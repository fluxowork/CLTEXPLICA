-- ============================================================
-- CLTExplica — supabase_schema.sql (versão completa v2)
-- Inclui: posts, categories, leads, site_settings, media, ads
-- ============================================================
-- Cole TODO este conteúdo no SQL Editor do Supabase e clique em Run ▶
-- ============================================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABELA: categories
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Leitura publica de categorias" ON categories
  FOR SELECT USING (true);

CREATE POLICY "Admin gerencia categorias" ON categories
  FOR ALL USING (auth.role() = 'authenticated');

-- Categorias iniciais
INSERT INTO categories (name, slug, description) VALUES
  ('Escalas de Trabalho',    'escalas-de-trabalho',    'Regras sobre jornada, escalas e horas extras'),
  ('Salário e Adicionais',   'salario-e-adicionais',   'Cálculo de salário, adicionais e benefícios'),
  ('FGTS e Benefícios',      'fgts-e-beneficios',      'Tudo sobre FGTS, vale-transporte e alimentação'),
  ('Direitos do Trabalhador','direitos-do-trabalhador', 'Seus direitos garantidos pela CLT'),
  ('Demissão e Rescisão',    'demissao-e-rescisao',    'Verbas rescisórias, aviso prévio e documentação'),
  ('Ferramentas CLT',        'ferramentas-clt',        'Calculadoras e guias práticos')
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- TABELA: posts (artigos do site)
-- ============================================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  content TEXT,
  excerpt TEXT,
  meta_description TEXT,
  category TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('published', 'draft', 'scheduled')),
  tags TEXT[] DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Leitura publica de posts publicados" ON posts
  FOR SELECT USING (status = 'published');

CREATE POLICY "Admin gerencia posts" ON posts
  FOR ALL USING (auth.role() = 'authenticated');

CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Artigos de exemplo
INSERT INTO posts (title, slug, excerpt, content, category, status, published_at) VALUES
(
  'Escala 6×1: o que diz a CLT e quais são seus direitos?',
  'escala-6x1-direitos',
  'Entenda como funciona a escala 6×1, o que a CLT determina e quais são os seus direitos como trabalhador.',
  '## O que é a escala 6×1?

A escala 6×1 é uma das modalidades de jornada de trabalho mais utilizadas no Brasil, especialmente no comércio varejista, supermercados e bares e restaurantes. Nessa escala, o trabalhador trabalha 6 dias e descansa 1 dia.

## O que diz a CLT?

O artigo 67 da CLT garante que todo trabalhador tem direito a um descanso semanal remunerado (DSR) de no mínimo 24 horas consecutivas, preferencialmente aos domingos.

## Jornada máxima diária

Na escala 6×1, a jornada diária não pode ultrapassar **8 horas diárias** e **44 horas semanais**. Qualquer hora trabalhada acima disso é considerada hora extra.

> **Atenção:** O trabalho aos domingos requer autorização das autoridades competentes e adicional de pelo menos 100% sobre o valor da hora normal.

## Seus direitos na escala 6×1

- Descanso semanal remunerado (DSR)
- Adicional de 100% para trabalho aos domingos
- Horas extras pagas com adicional mínimo de 50%
- Intervalo mínimo de 1 hora para refeição em jornadas acima de 6h',
  'Escalas de Trabalho',
  'published',
  NOW() - INTERVAL '10 days'
),
(
  'Como calcular hora extra: guia completo com exemplos práticos',
  'como-calcular-hora-extra',
  'Aprenda a calcular o valor correto das suas horas extras com exemplos práticos e a legislação atual.',
  '## O que é hora extra?

Hora extra é qualquer hora trabalhada além da jornada contratual do trabalhador. A CLT estabelece um adicional mínimo de **50% para dias úteis** e **100% para domingos e feriados**.

## Como calcular o valor da hora normal

Para calcular o valor da hora normal, divida o salário mensal por 220 (que representa a quantidade de horas mensais para uma jornada de 44h semanais):

**Valor da hora normal = Salário ÷ 220**

## Exemplo prático

Trabalhador com salário de R$ 2.000,00:

- Hora normal: R$ 2.000 ÷ 220 = **R$ 9,09**
- Hora extra (50%): R$ 9,09 × 1,50 = **R$ 13,64**
- Hora extra (100%): R$ 9,09 × 2,00 = **R$ 18,18**

> Use nossa calculadora gratuita para simular automaticamente o valor das suas horas extras!

## Limite de horas extras

A CLT permite no máximo **2 horas extras por dia**, exceto em casos especiais previstos em acordo coletivo.',
  'Salário e Adicionais',
  'published',
  NOW() - INTERVAL '5 days'
)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- TABELA: leads (captura de e-mails)
-- ============================================================
CREATE TABLE IF NOT EXISTS leads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Qualquer um pode inserir lead" ON leads
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin le leads" ON leads
  FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================
-- TABELA: site_settings (configurações do site)
-- ============================================================
CREATE TABLE IF NOT EXISTS site_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin gerencia configuracoes" ON site_settings
  FOR ALL USING (auth.role() = 'authenticated');

INSERT INTO site_settings (key, value) VALUES
  ('site_title',          'CLTExplica'),
  ('site_slogan',         'Seus direitos, sem complicação.'),
  ('site_email',          'contato@cltexplica.com.br'),
  ('meta_title',          'CLTExplica – Seus direitos CLT, sem complicação'),
  ('meta_description',    'Portal informativo sobre direitos e rotina do trabalhador CLT no Brasil. Calculadoras, guias e artigos gratuitos.'),
  ('google_analytics_id', ''),
  ('adsense_banner_code', ''),
  ('adsense_sidebar_code','')
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- TABELA: ads (gerenciador de anúncios numerados)
-- ============================================================
CREATE TABLE IF NOT EXISTS ads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ad_id TEXT NOT NULL UNIQUE,
  name TEXT,
  position TEXT DEFAULT 'banner-topo',
  type TEXT DEFAULT 'image' CHECK (type IN ('image', 'code')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  image_url TEXT,
  image_base64 TEXT,
  link TEXT,
  alt_text TEXT,
  html_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE ads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anuncios ativos publicos" ON ads
  FOR SELECT USING (status = 'active');

CREATE POLICY "Admin gerencia anuncios" ON ads
  FOR ALL USING (auth.role() = 'authenticated');

CREATE TRIGGER ads_updated_at
  BEFORE UPDATE ON ads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- TABELA: media (biblioteca de mídia — opcional)
-- ============================================================
CREATE TABLE IF NOT EXISTS media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  filename TEXT NOT NULL,
  url TEXT NOT NULL,
  size_bytes INTEGER,
  mime_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin gerencia midia" ON media
  FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================
-- FIM DO SCRIPT
-- Resultado esperado: "Success. No rows returned"
-- ============================================================
