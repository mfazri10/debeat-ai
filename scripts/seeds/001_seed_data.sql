-- ============================================================
-- SEED DATA: DebateAI
-- 10 Personas, 20 Debate Motions, 10 Badges
-- ============================================================

-- 1. SEED PERSONAS (5 Bahasa Indonesia, 5 English)
INSERT INTO personas (id, user_id, name, description, speaking_style, stance_default, language, is_template, is_active)
VALUES
    ('a0000000-0000-0000-0000-000000000001', NULL, 'Presiden RI', 'Kepala Negara yang tenang, berwibawa, dan mengedepankan persatuan nasional serta visi geopolitik Nusantara.', 'Tenang, terstruktur, diplomatis, mengutip kepentingan rakyat dan stabilitas bangsa.', 'NEUTRAL', 'id', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000002', NULL, 'Menteri Keuangan', 'Teknokrat ekonomi berbasis data fiskal, disiplin anggaran, dan keberlanjutan APBN.', 'Rasional, tajam berbasis angka statistik, tegas soal rasio utang dan produktivitas nasional.', 'NEUTRAL', 'id', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000003', NULL, 'Hakim Mahkamah Konstitusi', 'Penjaga konstitusi yang menitikberatkan hierarki hukum, hak asasi manusia, dan asas keadilan substantif.', 'Formal, analitis, merujuk pasal undang-undang dasar, menghindari argumen populis.', 'NEUTRAL', 'id', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000004', NULL, 'Aktivis Lingkungan', 'Pejuang keadilan iklim vokal yang mendesak transisi energi hijau dan perlindungan masyarakat adat.', 'Emosional penuh determinasi, retorika urgensi eksistensial, kritis terhadap eksploitasi korporasi.', 'PRO', 'id', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000005', NULL, 'CEO Startup Unicorn', 'Inovator disrupsi teknologi yang berfokus pada kecepatan eksekusi, kapitalisme ventura, dan adopsi AI.', 'Antusias, menggunakan istilah industri modern, pragmatis terhadap efisiensi dan skalabilitas pasar.', 'PRO', 'id', TRUE, TRUE),

    ('a0000000-0000-0000-0000-000000000006', NULL, 'US President', 'A statesman focused on democratic values, international alliances, and domestic resilience.', 'Charismatic, assertive, invoking democratic ideals and national security.', 'NEUTRAL', 'en', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000007', NULL, 'Harvard Professor', 'An academic dedicated to empirical rigor, conceptual precision, and peer-reviewed consensus.', 'Methodical, deeply reasoned, questioning core assumptions and citing scholarly precedent.', 'NEUTRAL', 'en', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000008', NULL, 'UN Diplomat', 'A multilateral negotiator committed to conflict resolution, international treaties, and human dignity.', 'Balanced, respectful, seeking common ground, fluent in multilateral governance.', 'NEUTRAL', 'en', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000009', NULL, 'Silicon Valley Tech CEO', 'A futurist driving artificial intelligence, space commercialization, and free-market optimism.', 'Visionary, bold, fast-paced, challenging bureaucratic friction.', 'PRO', 'en', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000010', NULL, 'Human Rights Lawyer', 'An advocate confronting systemic inequality, authoritarian creep, and civil liberties protection.', 'Principled, uncompromising on human rights covenants, fierce in cross-examination.', 'PRO', 'en', TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 2. SEED DEBATE MOTIONS (10 ID dari KDMI/NUDC, 10 EN dari WUDC/IDEA)
INSERT INTO debate_motions (id, text, category, format, language, difficulty, source)
VALUES
    -- Bahasa Indonesia (KDMI / NUDC)
    ('b0000000-0000-0000-0000-000000000001', 'Dewan ini akan mewajibkan adopsi kecerdasan buatan (AI) pada kurikulum pendidikan tinggi nasional.', 'EDUCATION', 'KDMI', 'ID', 'MEDIUM', 'KDMI 2024'),
    ('b0000000-0000-0000-0000-000000000002', 'Dewan ini percaya bahwa subsidi kendaraan listrik memperlebar kesenjangan ekonomi masyarakat.', 'ECONOMY', 'KDMI', 'ID', 'MEDIUM', 'KDMI 2024'),
    ('b0000000-0000-0000-0000-000000000003', 'Sebagai negara berkembang, Dewan ini akan memprioritaskan pertumbuhan ekonomi di atas target emisi nol bersih.', 'ENVIRONMENT', 'KDMI', 'ID', 'HARD', 'KDMI 2023'),
    ('b0000000-0000-0000-0000-000000000004', 'Dewan ini akan melarang penggunaan algoritma media sosial yang dirancang memicu kemarahan publik.', 'TECHNOLOGY', 'KDMI', 'ID', 'EASY', 'NUDC 2023'),
    ('b0000000-0000-0000-0000-000000000005', 'Dewan ini akan menerapkan pajak warisan agresif sebesar 50% untuk kekayaan di atas 50 miliar rupiah.', 'ECONOMY', 'KDMI', 'ID', 'HARD', 'KDMI 2024'),
    ('b0000000-0000-0000-0000-000000000006', 'Dewan ini menyesalkan hegemoni platform streaming asing terhadap industri perfilman lokal.', 'SOCIAL', 'KDMI', 'ID', 'EASY', 'NUDC 2024'),
    ('b0000000-0000-0000-0000-000000000007', 'Dewan ini akan menghapus ambang batas parlemen (parliamentary threshold) untuk pemilu legislatif.', 'POLITICS', 'KDMI', 'ID', 'HARD', 'KDMI 2024'),
    ('b0000000-0000-0000-0000-000000000008', 'Dewan ini akan memberikan status hak hukum subjek (legal personhood) kepada sungai dan hutan lindung.', 'LAW', 'KDMI', 'ID', 'HARD', 'NUDC 2023'),
    ('b0000000-0000-0000-0000-000000000009', 'Dewan ini akan melarang pemberian gelar influencer terhadap figur publik yang mempromosikan judi online terselubung.', 'LAW', 'KDMI', 'ID', 'EASY', 'KDMI 2024'),
    ('b0000000-0000-0000-0000-000000000010', 'Dewan ini mendukung desentralisasi total sistem gaji guru aparatur sipil negara ke pemerintah daerah.', 'EDUCATION', 'KDMI', 'ID', 'MEDIUM', 'NUDC 2024'),

    -- English (WUDC / IDEA)
    ('b0000000-0000-0000-0000-000000000011', 'This House would ban the commercial development of frontier autonomous AI weapon systems.', 'TECHNOLOGY', 'BP', 'EN', 'HARD', 'WUDC 2025'),
    ('b0000000-0000-0000-0000-000000000012', 'This House regrets the glorification of workaholism in competitive corporate economies.', 'SOCIAL', 'BP', 'EN', 'EASY', 'IDEA Debatabase'),
    ('b0000000-0000-0000-0000-000000000013', 'This House would condition IMF bailout packages on strict carbon reduction commitments.', 'ECONOMY', 'BP', 'EN', 'HARD', 'WUDC 2024'),
    ('b0000000-0000-0000-0000-000000000014', 'This House believes that developing nations should nationalize critical lithium and mineral extraction sectors.', 'ECONOMY', 'BP', 'EN', 'MEDIUM', 'WUDC 2024'),
    ('b0000000-0000-0000-0000-000000000015', 'This House would hold social media company executives personally criminally liable for algorithmic harm to minors.', 'LAW', 'OXFORD', 'EN', 'HARD', 'IDEA Debatabase'),
    ('b0000000-0000-0000-0000-000000000016', 'This House prefers a world where higher education admissions are based solely on standardized blind assessments.', 'EDUCATION', 'BP', 'EN', 'MEDIUM', 'WUDC 2023'),
    ('b0000000-0000-0000-0000-000000000017', 'This House would grant sovereign immunity waivers for cross-border climate damage lawsuits.', 'LAW', 'BP', 'EN', 'HARD', 'WUDC 2025'),
    ('b0000000-0000-0000-0000-000000000018', 'This House believes that universal basic income should replace all existing conditional welfare programs.', 'ECONOMY', 'OXFORD', 'EN', 'MEDIUM', 'IDEA Debatabase'),
    ('b0000000-0000-0000-0000-000000000019', 'This House would mandate public funding for all election campaigns and ban private political donations.', 'POLITICS', 'BP', 'EN', 'MEDIUM', 'WUDC 2023'),
    ('b0000000-0000-0000-0000-000000000020', 'This House supports geoengineering initiatives even without unanimous global consensus.', 'ENVIRONMENT', 'BP', 'EN', 'HARD', 'WUDC 2024')
ON CONFLICT (id) DO NOTHING;

-- 3. SEED BADGES (10 Badge Gamifikasi Dasar)
INSERT INTO badges (id, code, name, description, icon_url, category)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'first_debate', 'Debater Pertama', 'Selesaikan debat pertama Anda di arena DebateAI.', '/assets/badges/first_debate.png', 'general'),
    ('c0000000-0000-0000-0000-000000000002', 'first_win', 'Kemenangan Perdana', 'Menangkan debat pertama Anda melawan AI atau lawan kompetitif.', '/assets/badges/first_win.png', 'general'),
    ('c0000000-0000-0000-0000-000000000003', 'streak_3', 'Hat-trick', 'Raih 3 kali kemenangan beruntun di arena debat.', '/assets/badges/streak_3.png', 'streak'),
    ('c0000000-0000-0000-0000-000000000004', 'streak_5', 'Unstoppable', 'Raih 5 kali kemenangan beruntun tanpa terkalahkan.', '/assets/badges/streak_5.png', 'streak'),
    ('c0000000-0000-0000-0000-000000000005', 'points_100', 'Debater Resmi', 'Kumpulkan akumulasi 100 poin pengalaman gamifikasi.', '/assets/badges/points_100.png', 'mastery'),
    ('c0000000-0000-0000-0000-000000000006', 'points_500', 'Debater Ahli', 'Kumpulkan akumulasi 500 poin pengalaman gamifikasi.', '/assets/badges/points_500.png', 'mastery'),
    ('c0000000-0000-0000-0000-000000000007', 'points_1500', 'Debate Master', 'Kumpulkan akumulasi 1500 poin pengalaman gamifikasi.', '/assets/badges/points_1500.png', 'mastery'),
    ('c0000000-0000-0000-0000-000000000008', 'perfect_score', 'Sempurna', 'Raih skor 95+ dari seluruh dewan juri dalam satu argumen.', '/assets/badges/perfect_score.png', 'mastery'),
    ('c0000000-0000-0000-0000-000000000009', 'all_formats', 'Polyglot', 'Uji ketangkasan debat Anda di seluruh format (KDMI, Oxford, BP, NUDC, Interview).', '/assets/badges/all_formats.png', 'social'),
    ('c0000000-0000-0000-0000-000000000010', 'kb_contributor', 'Kontributor', 'Kirimkan materi Knowledge Base komunitas yang lolos kurasi review.', '/assets/badges/kb_contributor.png', 'social')
ON CONFLICT (id) DO NOTHING;
