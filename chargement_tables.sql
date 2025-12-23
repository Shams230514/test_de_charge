-- ============================================
-- SCRIPT COMPLET DE SEED - GO GAINDÉ
-- Exécuter dans l'ordre
-- ============================================

-- ============================================
-- 1. UTILISATEURS (10 000 users de test)
-- ============================================
-- Supprimer les anciens utilisateurs de test
DELETE FROM utilisateur WHERE email LIKE 'testuser%@gogainde.sn';

-- Créer 10 000 utilisateurs
INSERT INTO utilisateur (
    username, nom, prenom, phone_number, email, password, 
    code_secret, role, is_active, is_deleted, is_verified, 
    points_cumules, created_at, updated_at
)
SELECT 
    'testuser' || i,
    (ARRAY['Diop','Ndiaye','Sall','Ba','Faye','Gueye','Diallo','Sarr','Mbaye','Thiam'])[1 + (i % 10)],
    (ARRAY['Amadou','Fatou','Moussa','Aissatou','Ibrahima','Mariama','Ousmane','Awa','Cheikh','Ndèye'])[1 + (i % 10)],
    '+22177' || LPAD(i::text, 7, '0'),
    'testuser' || i || '@gogainde.sn',
    '$2a$10$grqNFD8k./tZsxptkrHVs.hwU2ANT0zYgJc4//GwHtooxF.NHiKIG',
    1234,
    'USER',
    true,
    false,
    true,
    FLOOR(RANDOM() * 500)::int,
    NOW() - (RANDOM() * INTERVAL '90 days'),
    NOW()
FROM generate_series(1, 10000) AS i
ON CONFLICT (phone_number) DO NOTHING;

-- ============================================
-- 2. CATÉGORIES DE PRODUITS
-- ============================================
INSERT INTO categorie_produit (nom_categorie, created_at, updated_at)
VALUES 
    ('Maillots', NOW(), NOW()),
    ('Accessoires', NOW(), NOW()),
    ('Équipements', NOW(), NOW()),
    ('Souvenirs', NOW(), NOW()),
    ('Chaussures', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ============================================
-- 3. PRODUITS (50 produits)
-- ============================================
INSERT INTO produit (libelle, description, prix, new_prix, quantity, disponible, is_deleted, nbr_points, categorie_produit_id, image_url, created_at, updated_at)
SELECT 
    'Produit ' || i || ' - ' || 
    CASE (i % 5)
        WHEN 0 THEN 'Maillot Domicile'
        WHEN 1 THEN 'Maillot Extérieur'
        WHEN 2 THEN 'Short Officiel'
        WHEN 3 THEN 'Écharpe Supporter'
        ELSE 'Ballon Officiel'
    END,
    'Description du produit ' || i || '. Produit officiel Go Gaindé pour supporter les Lions de la Teranga.',
    (10000 + (RANDOM() * 50000))::numeric(10,2),
    CASE WHEN RANDOM() > 0.7 THEN (8000 + (RANDOM() * 40000))::numeric(10,2) ELSE NULL END,
    FLOOR(10 + RANDOM() * 100)::int,
    true,
    false,
    FLOOR(RANDOM() * 100)::int,
    (SELECT id FROM categorie_produit ORDER BY RANDOM() LIMIT 1),
    'https://minio.gogainde.sn/produits/produit' || i || '.jpg',
    NOW(),
    NOW()
FROM generate_series(1, 50) AS i;

-- ============================================
-- 4. POSTS (200 posts)
-- ============================================
INSERT INTO post (title, description, image_url, category, is_video, is_deleted, share_count, auteur_id, created_at, updated_at)
SELECT 
    CASE (i % 6)
        WHEN 0 THEN 'Match contre ' || (ARRAY['Maroc','Mali','Côte d''Ivoire','Nigeria','Cameroun','Algérie'])[1 + (i % 6)]
        WHEN 1 THEN 'Entraînement des Lions'
        WHEN 2 THEN 'Interview de ' || (ARRAY['Sadio Mané','Kalidou Koulibaly','Édouard Mendy','Ismaïla Sarr'])[1 + (i % 4)]
        WHEN 3 THEN 'Les supporters à Dakar'
        WHEN 4 THEN 'Conférence de presse'
        ELSE 'Actualité de la sélection'
    END || ' #' || i,
    'Contenu du post numéro ' || i || '. Allez les Lions! 🦁 Le Sénégal est fier de sa sélection nationale. #TeamSenegal #AFCON2025',
    'https://minio.gogainde.sn/posts/post' || i || '.jpg',
    (ARRAY['ACTUALITES','MATCHS','JOUEURS','FANZONE','INTERVIEWS','ENTRAINEMENT'])[1 + (i % 6)],
    CASE WHEN RANDOM() > 0.8 THEN true ELSE false END,
    false,
    FLOOR(RANDOM() * 500)::int,
    1, -- admin comme auteur
    NOW() - (i || ' hours')::interval,
    NOW()
FROM generate_series(1, 200) AS i;

-- ============================================
-- 5. COMPETITION TEAMS
-- ============================================
INSERT INTO competition_teams (nom, confederation, traduction)
VALUES 
    ('CAN 2025', 'CAF', 'Coupe d''Afrique des Nations 2025'),
    ('Qualifications CAN', 'CAF', 'Éliminatoires CAN'),
    ('Qualifications Mondial', 'CAF', 'Éliminatoires Coupe du Monde')
ON CONFLICT DO NOTHING;

-- ============================================
-- 6. TEAMS (Équipes)
-- ============================================
INSERT INTO teams (nom_equipe, url_drapeau, competition_id)
SELECT 
    nom,
    'https://minio.gogainde.sn/flags/' || LOWER(REPLACE(nom, ' ', '_')) || '.png',
    (SELECT id FROM competition_teams LIMIT 1)
FROM (VALUES 
    ('Sénégal'), ('Maroc'), ('Mali'), ('Côte d''Ivoire'), ('Nigeria'),
    ('Cameroun'), ('Algérie'), ('Égypte'), ('Ghana'), ('Tunisie'),
    ('Burkina Faso'), ('Guinée'), ('RD Congo'), ('Afrique du Sud'), ('Zambie')
) AS t(nom)
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. MATCHS (30 matchs)
-- ============================================
INSERT INTO match (date, heure, stade, ville, groupe, phase, statut, competition_id, created_at, updated_at)
VALUES 
    -- Matchs passés
    ('2024-11-15', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Groupe A', 'Qualifications', 'TERMINE', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2024-11-18', '17:00', 'Stade LSS', 'Dakar', 'Groupe A', 'Qualifications', 'TERMINE', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2024-12-01', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Groupe A', 'Qualifications', 'TERMINE', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    -- Matchs à venir CAN 2025
    ('2025-01-15', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Groupe A', 'Phase de groupes', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-01-18', '17:00', 'Stade LSS', 'Dakar', 'Groupe A', 'Phase de groupes', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-01-21', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Groupe A', 'Phase de groupes', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-01-25', '17:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Huitièmes', 'Huitièmes de finale', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-01-28', '20:00', 'Stade LSS', 'Dakar', 'Quarts', 'Quarts de finale', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-02-01', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Demis', 'Demi-finale', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW()),
    ('2025-02-05', '20:00', 'Stade Abdoulaye Wade', 'Diamniadio', 'Finale', 'Finale', 'A_VENIR', (SELECT id FROM competition_teams LIMIT 1), NOW(), NOW());

-- Ajouter plus de matchs
INSERT INTO match (date, heure, stade, ville, groupe, phase, statut, competition_id, created_at, updated_at)
SELECT 
    ('2025-01-' || LPAD((10 + i)::text, 2, '0'))::varchar,
    CASE WHEN i % 2 = 0 THEN '17:00' ELSE '20:00' END,
    CASE WHEN i % 2 = 0 THEN 'Stade Abdoulaye Wade' ELSE 'Stade LSS' END,
    CASE WHEN i % 2 = 0 THEN 'Diamniadio' ELSE 'Dakar' END,
    'Groupe ' || CHR(65 + (i % 4)),
    'Phase de groupes',
    'A_VENIR',
    (SELECT id FROM competition_teams LIMIT 1),
    NOW(),
    NOW()
FROM generate_series(1, 20) AS i;

-- ============================================
-- 8. MATCH_TEAM (Associer équipes aux matchs)
-- ============================================
INSERT INTO match_team (match_id, team_id, is_home, score, nom_equipe, photo_url)
SELECT 
    m.id,
    t.id,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY t.id) = 1 THEN true ELSE false END,
    CASE WHEN m.statut = 'TERMINE' THEN FLOOR(RANDOM() * 4)::int ELSE NULL END,
    t.nom_equipe,
    t.url_drapeau
FROM match m
CROSS JOIN LATERAL (
    SELECT id, nom_equipe, url_drapeau 
    FROM teams 
    ORDER BY RANDOM() 
    LIMIT 2
) t
ON CONFLICT DO NOTHING;

-- ============================================
-- 9. ATTRIBUTES (pour les joueurs)
-- ============================================
INSERT INTO attributes (id, att, cre, def, tac, tec, aer, ant, bal, sav)
SELECT 
    i,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int,
    60 + FLOOR(RANDOM() * 35)::int
FROM generate_series(1, 30) AS i
ON CONFLICT DO NOTHING;

-- ============================================
-- 10. PLAYERS (30 joueurs sénégalais)
-- ============================================
INSERT INTO player (id, full_name, birth_date, age, height_cm, club, club_logo_url, jersey_number, 
    market_value_millions, primary_position, position_category, photo_url, 
    selections, matches_played, goals, trophies_won, preferred_foot, 
    strength, weakness, form_rating, attributes_id)
VALUES 
    (1, 'Sadio Mané', '1992-04-10', 32, 175, 'Al-Nassr', 'https://minio.gogainde.sn/clubs/alnassr.png', 10, 30, 'Ailier gauche', 'Attaquant', 'https://minio.gogainde.sn/players/mane.jpg', 100, 95, 45, 8, 'Droit', 'Vitesse, Dribble', 'Jeu de tête', '8.5', 1),
    (2, 'Kalidou Koulibaly', '1991-06-20', 33, 187, 'Al-Hilal', 'https://minio.gogainde.sn/clubs/alhilal.png', 3, 15, 'Défenseur central', 'Défenseur', 'https://minio.gogainde.sn/players/koulibaly.jpg', 75, 70, 3, 5, 'Droit', 'Force, Anticipation', 'Vitesse', '7.8', 2),
    (3, 'Édouard Mendy', '1992-03-01', 32, 197, 'Al-Ahli', 'https://minio.gogainde.sn/clubs/alahli.png', 1, 12, 'Gardien', 'Gardien', 'https://minio.gogainde.sn/players/mendy.jpg', 50, 48, 0, 3, 'Droit', 'Arrêts, Placement', 'Jeu au pied', '7.5', 3),
    (4, 'Ismaïla Sarr', '1998-02-25', 26, 185, 'Marseille', 'https://minio.gogainde.sn/clubs/om.png', 7, 25, 'Ailier droit', 'Attaquant', 'https://minio.gogainde.sn/players/sarr.jpg', 60, 55, 15, 2, 'Droit', 'Vitesse, Frappe', 'Décisions', '8.0', 4),
    (5, 'Idrissa Gana Gueye', '1989-09-26', 35, 174, 'Everton', 'https://minio.gogainde.sn/clubs/everton.png', 27, 5, 'Milieu défensif', 'Milieu', 'https://minio.gogainde.sn/players/gueye.jpg', 99, 90, 5, 4, 'Droit', 'Récupération, Énergie', 'Création', '7.2', 5),
    (6, 'Abdou Diallo', '1996-05-04', 28, 187, 'Lyon', 'https://minio.gogainde.sn/clubs/lyon.png', 22, 10, 'Défenseur central', 'Défenseur', 'https://minio.gogainde.sn/players/diallo.jpg', 40, 38, 1, 2, 'Gauche', 'Relance, Polyvalence', 'Duels aériens', '7.0', 6),
    (7, 'Boulaye Dia', '1996-11-16', 28, 180, 'Lazio', 'https://minio.gogainde.sn/clubs/lazio.png', 19, 18, 'Attaquant', 'Attaquant', 'https://minio.gogainde.sn/players/dia.jpg', 30, 28, 12, 1, 'Droit', 'Finition, Appels', 'Jeu de tête', '7.8', 7),
    (8, 'Pape Matar Sarr', '2002-09-14', 22, 184, 'Tottenham', 'https://minio.gogainde.sn/clubs/tottenham.png', 29, 35, 'Milieu central', 'Milieu', 'https://minio.gogainde.sn/players/pmatar.jpg', 25, 22, 3, 0, 'Droit', 'Technique, Vision', 'Physique', '8.2', 8),
    (9, 'Nicolas Jackson', '2001-06-20', 23, 186, 'Chelsea', 'https://minio.gogainde.sn/clubs/chelsea.png', 15, 45, 'Attaquant', 'Attaquant', 'https://minio.gogainde.sn/players/jackson.jpg', 15, 14, 8, 0, 'Droit', 'Vitesse, Finition', 'Régularité', '8.3', 9),
    (10, 'Iliman Ndiaye', '2000-03-06', 24, 177, 'Everton', 'https://minio.gogainde.sn/clubs/everton.png', 10, 20, 'Meneur de jeu', 'Milieu', 'https://minio.gogainde.sn/players/ndiaye.jpg', 20, 18, 5, 0, 'Droit', 'Dribble, Créativité', 'Défense', '7.9', 10);

-- Générer 20 joueurs supplémentaires
INSERT INTO player (id, full_name, birth_date, age, height_cm, club, jersey_number, 
    market_value_millions, primary_position, position_category, 
    selections, matches_played, goals, trophies_won, preferred_foot, attributes_id)
SELECT 
    10 + i,
    'Joueur Test ' || i,
    '199' || (i % 10) || '-0' || (1 + i % 9) || '-15',
    25 + (i % 10),
    170 + (i % 20),
    (ARRAY['Monaco','Nice','Rennes','Lens','RC Strasbourg','Angers','FC Metz'])[1 + (i % 7)],
    i,
    5 + (i % 30),
    (ARRAY['Défenseur central','Milieu défensif','Milieu central','Ailier droit','Ailier gauche','Attaquant','Gardien'])[1 + (i % 7)],
    (ARRAY['Défenseur','Milieu','Attaquant','Gardien'])[1 + (i % 4)],
    10 + (i % 50),
    10 + (i % 45),
    i % 15,
    i % 5,
    CASE WHEN i % 3 = 0 THEN 'Gauche' ELSE 'Droit' END,
    10 + i
FROM generate_series(1, 20) AS i
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 11. QUIZ (5 quiz avec questions)
-- ============================================
INSERT INTO quiz (titre, description, est_actif, createur_id, date_creation, created_at, updated_at)
VALUES 
    ('Quiz Histoire des Lions', 'Testez vos connaissances sur l''histoire du football sénégalais', true, 1, NOW(), NOW(), NOW()),
    ('Quiz CAN 2022', 'Tout sur la victoire historique à la CAN 2022', true, 1, NOW(), NOW(), NOW()),
    ('Quiz Joueurs Actuels', 'Connaissez-vous les Lions de la Teranga actuels?', true, 1, NOW(), NOW(), NOW()),
    ('Quiz Stades du Sénégal', 'Les enceintes sportives sénégalaises', true, 1, NOW(), NOW(), NOW()),
    ('Quiz Légendes', 'Les légendes du football sénégalais', false, 1, NOW(), NOW(), NOW());

-- ============================================
-- 12. QUESTIONS (10 par quiz)
-- ============================================
INSERT INTO question (texte_question, points, temps_reponse, quiz_id, created_at, updated_at)
SELECT 
    'Question ' || q_num || ' du quiz ' || quiz.id || ': ' ||
    CASE (q_num % 5)
        WHEN 0 THEN 'Qui a marqué le penalty victorieux en finale de la CAN 2022?'
        WHEN 1 THEN 'En quelle année le Sénégal a-t-il atteint la finale de la Coupe du Monde?'
        WHEN 2 THEN 'Quel est le surnom de l''équipe nationale du Sénégal?'
        WHEN 3 THEN 'Combien de fois le Sénégal a-t-il remporté la CAN?'
        ELSE 'Quel joueur sénégalais a remporté le Ballon d''Or africain en 2022?'
    END,
    10 + (q_num % 3) * 5,
    20 + (q_num % 4) * 10,
    quiz.id,
    NOW(),
    NOW()
FROM quiz
CROSS JOIN generate_series(1, 10) AS q_num;

-- ============================================
-- 13. RÉPONSES (4 par question)
-- ============================================
INSERT INTO reponse (texte_reponse, est_correcte, question_id, created_at, updated_at)
SELECT 
    CASE r_num
        WHEN 1 THEN 'Réponse correcte'
        WHEN 2 THEN 'Réponse incorrecte A'
        WHEN 3 THEN 'Réponse incorrecte B'
        ELSE 'Réponse incorrecte C'
    END,
    CASE WHEN r_num = 1 THEN true ELSE false END,
    q.id,
    NOW(),
    NOW()
FROM question q
CROSS JOIN generate_series(1, 4) AS r_num;

-- ============================================
-- 14. STATISTIQUES FINALES
-- ============================================
SELECT 'utilisateur' as table_name, COUNT(*) as count FROM utilisateur
UNION ALL SELECT 'categorie_produit', COUNT(*) FROM categorie_produit
UNION ALL SELECT 'produit', COUNT(*) FROM produit
UNION ALL SELECT 'post', COUNT(*) FROM post
UNION ALL SELECT 'match', COUNT(*) FROM match
UNION ALL SELECT 'teams', COUNT(*) FROM teams
UNION ALL SELECT 'player', COUNT(*) FROM player
UNION ALL SELECT 'quiz', COUNT(*) FROM quiz
UNION ALL SELECT 'question', COUNT(*) FROM question
UNION ALL SELECT 'reponse', COUNT(*) FROM reponse
ORDER BY table_name;