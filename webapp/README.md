# AppliVin Web

Version web (SPA statique) de l'app iOS AppliVin.

## Fonctionnalites
- Accueil avec actions principales.
- Creation / edition / suppression de fiches de vin.
- Stockage local via `localStorage`.
- Roue des aromes interactive (SVG) avec details de categories.

## Lancer en local
Depuis la racine du repo:

```bash
cd webapp
python3 -m http.server 8080
```

Puis ouvrir [http://localhost:8080](http://localhost:8080).

## Publier sur GitHub Pages (repo `florent198/applivin`)
1. Commit/push les fichiers.
2. Dans GitHub: `Settings` -> `Pages`.
3. Source: `Deploy from a branch`.
4. Branch: `main` (ou `master`) et dossier `/webapp`.
5. Sauvegarder.

GitHub Pages publiera ensuite l'app web automatiquement.
