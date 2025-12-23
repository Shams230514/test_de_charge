# Installer K6 sur ta machine : winget install Grafana.k6

# Installer postgres pour les requêtes sur la base : winget install PostgreSQL.psql : winget install PostgreSQL.PostgreSQL.17

# Mettre le script de test et le script de chargement des données dans un dossier sur lequel tu feras un cd

# Vérifie d'abord si les tables existes et quelles sont les données qu'elles disposent : psql "postgresql://db_user:password@host:port/database?sslmode=require" -c "\dt"

# Chargement des données : psql "postgresql://db_user:password@host:port/database?sslmode=require" -f chargement_tables.sql

# Vérifie le chargement : psql "postgresql://db_user:password@host:port/database?sslmode=require" -c "SELECT COUNT(*) FROM utilisateur;"

# Vérifie le hash du password si c'est après chargement : psql "postgresql://db_user:password@host:port/database?sslmode=require" -c "SELECT email, password FROM utilisateur WHERE email = 'admin@accel.tech';" 
ensuite psql "postgresql://db_user:password@host:port/database?sslmode=require" -c "SELECT email, password FROM utilisateur WHERE email = 'testuser1@gogainde.sn';" les deux doivent être identiques si différent faut exécuter 
psql "postgresql://db_user:password@host:port/database?sslmode=require" -c "UPDATE utilisateur SET password = (SELECT password FROM utilisateur WHERE email = 'admin@accel.tech') WHERE email LIKE 'testuser%@gogainde.sn';"

# Dépendant de l'environnement à tester faut changer le const BASE_URL = __ENV.BASE_URL par le bon lien

# Lance le test : k6 run -e VUS=100 k6-gogainde-modular.js // Faut changer l'occurence VUS=100 ensuite VUS=500 puis VUS=1000 etc.
