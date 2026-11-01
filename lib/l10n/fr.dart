/// French UI strings, keyed by the English text in the code (see l10n.dart).
///
/// Québec-friendly French. Labels on the TV are often narrow, so common
/// abbreviations are used on purpose (MAJ, PJ/V/D for standings, etc.).
/// Keep every `{placeholder}` exactly as in the key. `{s}` is the plural "s"
/// the code fills in ("chaîne{s}").
const Map<String, String> kFr = {
  "Discord": "Discord",
  "Direct support through Discord": "Aide directe sur Discord",
  "Questions, help with setup, feature ideas and release news: join the VesperTV community on Discord.":
      "Questions, aide à la configuration, idées et nouvelles versions : rejoignez la communauté VesperTV sur Discord.",
  "VesperTV is free, with no ads. A coffee or a Supporter membership helps cover its costs.":
      "VesperTV est gratuit et sans publicité. Un café ou un abonnement Supporter aide à couvrir ses frais.",
  "Show a test popup": "Afficher une fenêtre test",
  "A sample goal alert for 8 seconds.":
      "Un exemple d'alerte de but pendant 8 secondes.",
  "Guide": "Guide",
  "Live TV guide layout, full-screen video, compact rows":
      "Disposition du guide, vidéo plein écran, lignes compactes",
  "{n} titles": "{n} titres",
  "Open groups as expanded catalog": "Ouvrir les groupes en catalogue étendu",
  "Movies and TV Shows groups open the full poster grid instead of the rows.":
      "Les groupes Films et Séries s'ouvrent en grille d'affiches complète plutôt qu'en rangées.",
  "Compact guide": "Guide compact",
  "Shorter Timeline rows so more channels fit in the same space.":
      "Lignes de la grille plus courtes pour afficher plus de chaînes.",
  "Transparent popups": "Fenêtres transparentes",
  "Reminders and goal alerts lose their background and outline, keeping only the logo and text.":
      "Les rappels et alertes de but perdent leur fond et leur contour, il ne reste que le logo et le texte.",
  "Use with playlist": "Utiliser avec la playlist",
  "Save EPG URL": "Enregistrer l'URL du guide",
  "Custom EPG URL saved.": "URL du guide perso enregistrée.",
  "Custom EPG URL cleared.": "URL du guide perso supprimée.",
  "Pick a playlist, then paste a third-party XMLTV link. Leave it blank to use the guide of that playlist. A channel is only filled in when the ids in the feed match the playlist.":
      "Choisissez une playlist, puis collez un lien XMLTV tiers. Laissez vide pour utiliser le guide de la playlist. Une chaîne n'est remplie que si les identifiants de la source correspondent à ceux de la playlist.",
  // Sports Trak quality preference (moved from the league bar).
  "Prefer higher-quality channels among game matches":
      "Privilégier les chaînes de meilleure qualité parmi les correspondances du match",
  "On by default. Your saved channel choices still come first. Turn this off to keep the usual match order. Saved for this viewer.":
      "Activé par défaut. Vos choix de chaînes enregistrés restent prioritaires. Désactivez cette option pour conserver l’ordre habituel des correspondances. Enregistré pour ce profil.",
  // Android phone player touch lock.
  "Lock touch controls": "Verrouiller les commandes tactiles",
  "Unlock touch controls": "Déverrouiller les commandes tactiles",
  "Touch controls locked": "Commandes tactiles verrouillées",
  // Media Hub custom posters.
  "Add {imdb_id} or {tmdb_id} where the title goes.":
      "Ajoutez {imdb_id} ou {tmdb_id} à l'endroit du titre.",
  "Custom posters": "Affiches personnalisées",
  "Custom posters off: Media Hub shows the sources' posters.":
      "Affiches personnalisées désactivées : le Media Hub montre les affiches des sources.",
  "Example: {url}": "Exemple : {url}",
  "Media Hub posters from a poster service":
      "Affiches du Media Hub d'un service d'affiches",
  "Poster address": "Adresse des affiches",
  "Saved. Media Hub posters now come from this address.":
      "Enregistré. Les affiches du Media Hub viennent maintenant de cette adresse.",
  "Show Media Hub posters from a poster service of your choice, for example one that adds ratings. Paste its poster address with {imdb_id} (or {tmdb_id}) where the title goes; include your own key if the service needs one.":
      "Affichez les affiches du Media Hub depuis le service de votre choix, par exemple un service qui ajoute les cotes. Collez son adresse d'affiche avec {imdb_id} (ou {tmdb_id}) à l'endroit du titre; incluez votre propre clé si le service en demande une.",
  "Turn off": "Désactiver",
  "When a title has no matching ID, its normal poster is shown. Leave empty to turn it off.":
      "Si un titre n'a pas l'identifiant voulu, son affiche habituelle est montrée. Laissez vide pour désactiver.",
  // Media Hub experience (progressive sources, rows, discovery).
  "Add your TMDB key for collections and cast credits":
      "Ajoutez votre clé TMDB pour les collections et la distribution",
  "Airs {date}": "Diffusion {date}",
  "All sources": "Toutes les sources",
  "Any source": "N'importe quelle source",
  "Auto-play preferred stream": "Lire automatiquement le flux préféré",
  "Cast and credits": "Distribution et crédits",
  "Collection": "Collection",
  "Continue series": "Continuer la série",
  "Could not load credits.": "Impossible de charger les crédits.",
  "Could not load this title. Try again.":
      "Impossible de charger ce titre. Réessayez.",
  "Customize": "Personnaliser",
  "Customize Media Hub": "Personnaliser le Media Hub",
  "Customize rows": "Personnaliser les rangées",
  "Explore more": "Explorer plus",
  "Explore this genre": "Explorer ce genre",
  "Hide a row without disabling its playback source.":
      "Masquez une rangée sans désactiver sa source de lecture.",
  "Hide row": "Masquer la rangée",
  "If no stream matches, choose one manually. Format and language information comes from your sources.":
      "Si aucun flux ne correspond, choisissez-en un manuellement. Le format et la langue proviennent de vos sources.",
  "Leave empty to reset": "Laissez vide pour réinitialiser",
  "Loading": "Chargement",
  "Loading recommendations…": "Chargement des recommandations…",
  "Looking for streams…": "Recherche de flux…",
  "Maximum quality": "Qualité maximale",
  "More like this": "Dans le même genre",
  "No compatible source for this title. Add a playback source in Media Hub settings.":
      "Aucune source compatible pour ce titre. Ajoutez une source de lecture dans les paramètres du Media Hub.",
  "No credits found.": "Aucun crédit trouvé.",
  "No results": "Aucun résultat",
  "No streams": "Aucun flux",
  "Pin row": "Épingler la rangée",
  "Playback preferences": "Préférences de lecture",
  "Prefer SDR": "Préférer le SDR",
  "Preferred source": "Source préférée",
  "Rename row": "Renommer la rangée",
  "Results": "Résultats",
  "Retry recommendations": "Réessayer les recommandations",
  "Search sources": "Sources de recherche",
  "Show row": "Afficher la rangée",
  "Sources": "Sources",
  "Sources · searching…": "Sources · recherche…",
  "Unavailable": "Indisponible",
  "subtitles": "sous-titres",
  // Sports matchup information and activation.
  "Key stats": "Stats clés",
  "Latest goal": "Dernier but",
  "Last play": "Dernière action",
  "Game situation": "Situation du match",
  "OK: watch here  ·  Hold: pick the channel":
      "OK : regarder ici  ·  Maintenir : choisir la chaîne",
  "Click: watch here  ·  Hold: pick the channel":
      "Cliquer : regarder ici  ·  Maintenir : choisir la chaîne",
  "Open full Live TV": "Ouvrir Télé en direct complète",
  // Startup profile selector.
  "Launch with profiles selector": "Lancer avec le sélecteur de profils",
  "Choose a profile after the splash, before the app opens. Applies from the next start.":
      "Choisissez un profil après l’écran de démarrage, avant l’ouverture de l’application. S’applique au prochain démarrage.",
  "Who is watching?": "Qui regarde?",
  "Choose your profile to get started.":
      "Choisissez votre profil pour commencer.",
  "Welcome, {name}": "Bienvenue, {name}",
  "Could not switch profile. Please try again.":
      "Impossible de changer de profil. Veuillez réessayer.",

  "Sports Mode": "Mode Sports",
  "Make Sports Trak your home, with your top five leagues at the side.":
      "Faites de Sports Trak votre accueil, avec vos cinq premières ligues sur le côté.",
  "Could not change Sports Mode. Try again.":
      "Impossible de changer le mode Sports. Réessayez.",
  // Media Hub source cards.
  "Enabled": "Activée",
  "Catalogs from Cinemeta": "Catalogues de Cinemeta",
  "Media server": "Serveur multimédia",
  "Tracker lists": "Listes de suivi",
  "Catalogs only": "Catalogues seulement",
  "Streams only": "Flux seulement",
  "Catalogs + streams": "Catalogues + flux",
  "Provides video playback": "Fournit la lecture vidéo",
  "Refresh Media Hub after changing Other.":
      "Actualisez Media Hub après avoir modifié Autres.",
  "Playback sources": "Sources de lecture",
  "These sources provide the video when you press Play.":
      "Ces sources fournissent la vidéo quand vous appuyez sur Lire.",
  "No playback sources yet.": "Aucune source de lecture pour le moment.",
  "Catalogs & lists": "Catalogues et listes",
  "Discover titles here; playback comes from your sources above.":
      "Découvrez des titres ici; la lecture utilise vos sources ci-dessus.",
  "Popular · New · Featured": "Populaires · Nouveautés · En vedette",
  "Catalogs for stream-only sources":
      "Catalogues pour les sources de flux seulement",
  "Posters and episode details may still use Cinemeta when this is off.":
      "Les affiches et détails des épisodes peuvent utiliser Cinemeta même si cette option est désactivée.",
  "Hold OK on Enabled to remove a source.":
      "Maintenez OK sur Activée pour retirer une source.",
  "Show under Other keeps a source behind the Other genre filter in Movies and TV Shows.":
      "Afficher dans Autres place une source derrière le filtre de genre Autres dans Films et Séries.",

  "Remove from history": "Retirer de l’historique",
  "Automatically play the largest file":
      "Lire automatiquement le plus gros fichier",
  "Use the largest known file size when starting a title. Resume keeps your selected stream.":
      "Choisir le plus gros fichier connu au démarrage. La reprise conserve le flux sélectionné.",
  "Prefer highest quality": "Préférer la meilleure qualité",
  "Remind me for every game: {team}": "Me rappeler chaque match : {team}",
  "Stop team reminders: {team}": "Désactiver les rappels : {team}",
  "Remind me": "Me rappeler",
  "Cancel reminder": "Annuler le rappel",
  "15 minutes before and at game time (while VesperTV is open)":
      "15 minutes avant et au début du match (VesperTV doit être ouvert)",
  "Reminder set": "Rappel activé",
  "Reminder cancelled": "Rappel annulé",
  "Could not save reminder.": "Impossible d’enregistrer le rappel.",
  "This game has already started.": "Ce match a déjà commencé.",
  "Your team: {home} vs {away}": "Votre équipe : {home} contre {away}",
  "Starts in 15 minutes": "Commence dans 15 minutes",
  "Is about to start": "Le match va commencer",

  "Display": "Affichage",
  "Match the TV to the video's frame rate and resolution":
      "Adapter le téléviseur à la fréquence d’images et à la résolution de la vidéo",
  "Match frame rate": "Adapter la fréquence d’images",
  "Switches the TV to the video's frame rate a few seconds after it starts (50 Hz for UK and European channels, 24 Hz for films), for smooth motion. The screen goes black for a second or two while the TV switches; channels with the same rate don't switch again. Leaving the app gives the TV its own setting back.":
      "Passe le téléviseur à la fréquence d’images de la vidéo quelques secondes après le début (50 Hz pour les chaînes britanniques et européennes, 24 Hz pour les films), pour un mouvement fluide. L’écran devient noir une ou deux secondes pendant le changement; les chaînes à la même fréquence ne changent plus. En quittant l’app, le téléviseur reprend son propre réglage.",
  "Only switch between 50 and 60 Hz": "Changer seulement entre 50 et 60 Hz",
  "Films at 24 frames per second keep the current rate, so fewer switches.":
      "Les films à 24 images par seconde gardent la fréquence actuelle : moins de changements.",
  "Match resolution": "Adapter la résolution",
  "Switches the TV to the video's resolution (1080p, 4K…) so the TV does the upscaling. Off: this device scales every video to its current resolution.":
      "Passe le téléviseur à la résolution de la vidéo (1080p, 4K…) pour que le téléviseur fasse la mise à l’échelle. Désactivé : cet appareil met chaque vidéo à sa résolution actuelle.",
  "Stream HDR": "HDR du flux",
  "No (SDR)": "Non (SDR)",
  "Home": "Accueil",
  "Today's games": "Matchs du jour",
  "Recent channels": "Chaînes récentes",
  "Favourite channels": "Chaînes favorites",
  "New movies": "Nouveaux films",
  "New TV shows": "Nouvelles séries",
  'Series': "Série",
  "Movie": "Film",
  "Move row up": "Monter la rangée",
  "Move row down": "Descendre la rangée",
  "Hide this row": "Masquer cette rangée",
  "Edit Home rows…": "Modifier les rangées de l’accueil…",
  "Home rows": "Rangées de l’accueil",
  "Nothing here yet. Watch a channel, a movie or a show and it shows up on Home.":
      "Rien pour l’instant. Regardez une chaîne, un film ou une série et ils apparaîtront ici.",
  "Native video surface (beta)": "Surface vidéo native (bêta)",
  "Plays the picture the way native TV apps do, for HDR that looks washed out or green flashes under the guide (Fire TV Cube, NVIDIA Shield). Restart the app after changing it. If the picture is missing, in the wrong place or menus look wrong, turn it off and send us a log.":
      "Affiche l’image comme les applications TV natives, pour un HDR délavé ou des éclairs verts sous le guide (Fire TV Cube, NVIDIA Shield). Redémarrez l’application après l’avoir modifié. Si l’image manque, est mal placée ou si les menus s’affichent mal, désactivez-le et envoyez-nous un journal.",
  "Close the app completely and open it again to apply this change.":
      "Fermez complètement l’application et rouvrez-la pour appliquer ce changement.",
  "Green flicker fix (test)": "Correctif du scintillement vert (test)",
  "For green flashes on the picture while the guide or a menu is over it (NVIDIA Shield). Unlike Compatibility video it keeps HDR. Applies from the next channel. If the guide or menus disappear behind the video, turn it off.":
      "Pour les éclairs verts sur l’image quand le guide ou un menu est par-dessus (NVIDIA Shield). Contrairement à Vidéo compatible, le HDR est conservé. S’applique à la prochaine chaîne. Si le guide ou les menus disparaissent derrière la vidéo, désactivez-le.",
  'Automatic: on for this device.': 'Automatique : activé pour cet appareil.',
  '1 hour': '1 heure',
  '{h} hours': '{h} heures',

  'Sort groups': 'Trier les groupes',
  'Provider order': 'Ordre du fournisseur',
  'Name A–Z': 'Nom A–Z',
  'Name Z–A': 'Nom Z–A',

  // ── Startup / catalog sync ───────────────────────────────────────────
  'Starting...': "Démarrage…",
  'Content updated': "Contenu mis à jour",
  'Startup failed:\n{bootstrapError}': "Échec du démarrage :\n{bootstrapError}",
  'Retry': "Réessayer",
  'Your catalog has never been fully synced.':
      "Votre catalogue n'a jamais été entièrement synchronisé.",
  'Your catalog was last fully synced earlier today.':
      "Dernière synchro complète du catalogue : plus tôt aujourd'hui.",
  'Your catalog was last fully synced {days} day{s} ago.':
      "Dernière synchro complète du catalogue : il y a {days} jour{s}.",
  'Update content now?': "Mettre à jour le contenu?",
  'This can take a few minutes on a large catalog. Skipping opens the app with what\'s already cached.':
      "Ça peut prendre quelques minutes avec un gros catalogue. Si vous passez, l'appli s'ouvre avec ce qui est déjà en cache.",
  'Skip for now': "Plus tard",
  'Update': "Mettre à jour",
  'Loading movies & TV shows...': "Chargement des films et séries…",
  'Connecting to server...': "Connexion au serveur…",
  'Updating Content': "Mise à jour du contenu",
  '{done} / {total} categories': "{done} / {total} catégories",
  'This happens every few days to keep your catalog current — everyday launches open straight in.':
      "Ça se fait aux quelques jours pour garder votre catalogue à jour — les autres jours, l'appli s'ouvre directement.",
  'Re-checks every visible category for new content. This can take a few minutes on a large catalog.':
      "Revérifie chaque catégorie visible pour du nouveau contenu. Ça peut prendre quelques minutes avec un gros catalogue.",
  'Cancel': "Annuler",

  // ── Multiview ────────────────────────────────────────────────────────
  'Multiview': "Multivue",
  'Layout': "Disposition",
  '2 channels': "2 chaînes",
  '4 channels': "4 chaînes",
  '= audio — click a channel to switch':
      "= audio — cliquez sur une chaîne pour changer",
  'Reload': "Recharger",
  'Change channel': "Changer de chaîne",
  'Remove': "Retirer",
  'Search channels...': "Rechercher des chaînes…",
  'Before you start': "Avant de commencer",
  'Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn\'t, hold Select on it and choose Reload.':
      "Chaque écran de la Multivue est une connexion distincte à votre fournisseur. Votre liste doit permettre au moins autant de connexions que d'écrans ouverts (voir Connexions max. dans Gestion des listes).\n\nSi deux écrans partagent un compte qui ne permet qu'une connexion, ils se déconnectent l'un l'autre et vont figer ou charger sans arrêt. Astuce : prenez des chaînes de listes différentes, une par compte.\n\nUn écran figé redémarre tout seul. Sinon, maintenez OK dessus et choisissez Recharger.",
  'Don\'t show this again': "Ne plus afficher",
  'OK': "OK",
  'Couldn\'t start that channel': "Impossible de lancer cette chaîne",
  'Full screen': "Plein écran",
  'Windowed': "Fenêtré",
  '4 screens': "4 écrans",
  '1 + 3 screens': "1 + 3 écrans",
  'Move to the big screen': "Mettre sur le grand écran",
  'Swap mode': "Mode échange",
  'SWAP': "ÉCHANGE",
  'Arrows swap · OK or Back to finish':
      "Flèches : échanger · OK ou Retour : terminer",
  '2 screens': "2 écrans",
  '= audio — Select to switch, hold Select for options':
      "= audio — OK pour changer, maintenir OK pour les options",
  'Pick a channel': "Choisir une chaîne",
  'No channels found': "Aucune chaîne trouvée",
  'Open in Multiview': "Ouvrir en Multivue",

  // ── Player ───────────────────────────────────────────────────────────
  'Recall — recently watched': "Rappel — chaînes récentes",
  'No other live channels watched yet this session.':
      "Aucune autre chaîne en direct regardée pendant cette session.",
  'Recall — go back to a recent channel':
      "Rappel — revenir à une chaîne récente",
  'Remove from favorites': "Retirer des favoris",
  'Add to favorites': "Ajouter aux favoris",
  'Reload channel': "Recharger la chaîne",
  'Previous episode': "Épisode précédent",
  'Next episode': "Épisode suivant",
  'Ending now': "Fin imminente",
  '{minutes} min left': "Encore {minutes} min",
  'Back': "Retour",
  'Fit to screen': "Ajuster à l'écran",
  'Fill screen': "Remplir l'écran",
  'Closed captions (CC) — if the channel broadcasts them':
      "Sous-titres codés (CC) — si la chaîne les diffuse",
  'Up Next': "À suivre",
  'Playing in {countdown}s': "Lecture dans {countdown} s",
  'Playing now...': "Lecture…",
  'Play now': "Lire maintenant",
  'Dismiss': "Ignorer",
  'Select a channel to start watching': "Choisissez une chaîne pour commencer",
  'Switch to {p}: {name}': "Passer à {p} : {name}",
  'Switch to {playlistName}: {name}': "Passer à {playlistName} : {name}",
  'Technical details': "Détails techniques",
  "This is a Dolby Vision video, and this device can't play this kind of Dolby Vision. Pick a version without DV (HDR10 or SDR) if your source has one.":
      "Cette vidéo est en Dolby Vision, et cet appareil ne peut pas lire ce type de Dolby Vision. Choisissez une version sans DV (HDR10 ou SDR) si votre source en propose une.",
  "This stream kept dropping and restarting, so playback was stopped. Try the channel again in a moment, or pick another one.":
      "Ce flux n'arrêtait pas de se couper et de redémarrer, la lecture a donc été arrêtée. Réessayez la chaîne dans un instant ou choisissez-en une autre.",
  'This device\'s video decoder couldn\'t play this stream — likely 4K HDR (HEVC 10-bit). If your provider offers an HD (non-4K) version of this channel or title, try that. If another app plays this stream on this device, please report it with a photo of the technical details below.':
      "Le décodeur vidéo de cet appareil n'a pas pu lire ce flux — probablement du 4K HDR (HEVC 10 bits). Si votre fournisseur offre une version HD (non 4K) de cette chaîne ou de ce titre, essayez-la. Si une autre appli lit ce flux sur cet appareil, signalez-le avec une photo des détails techniques ci-dessous.",
  'Playback error:\n{raw}': "Erreur de lecture :\n{raw}",
  "Server error {code}": "Erreur serveur {code}",
  "The provider's server had a problem. Try again in a moment.":
      "Le serveur du fournisseur a rencontré un problème. Réessayez dans un instant.",
  "The provider refused the stream: check that your account is active and not already in use on another device.":
      "Le fournisseur a refusé le flux : vérifiez que votre compte est actif et pas déjà utilisé sur un autre appareil.",
  "The provider has no stream at this address: the channel or title may have been removed.":
      "Le fournisseur n'a aucun flux à cette adresse : la chaîne ou le titre a peut-être été retiré.",
  "The provider rejected the request.": "Le fournisseur a rejeté la demande.",
  "Couldn't reach the provider's server. Check your internet connection, or the server may be down.":
      "Impossible de joindre le serveur du fournisseur. Vérifiez votre connexion Internet, ou le serveur est peut-être hors service.",
  "Couldn't find the provider's server address. Check your internet connection or DNS settings, or try again later.":
      "Impossible de trouver l'adresse du serveur du fournisseur. Vérifiez votre connexion Internet ou vos paramètres DNS, ou réessayez plus tard.",
  'Subtitles': "Sous-titres",
  "1 game": "1 match",
  "{live} live": "{live} en direct",
  "Leagues with games": "Ligues avec des matchs",
  "All leagues": "Toutes les ligues",
  "{n} games": "{n} matchs",
  "{n} games · {live} live": "{n} matchs · {live} en direct",
  "No games": "Aucun match",
  "Favourite networks": "Réseaux favoris",
  "Favourite this network": "Ajouter ce réseau aux favoris",
  "Remove from favourite networks": "Retirer des réseaux favoris",
  "Networks": "Réseaux",
  "Other sports channels": "Autres chaînes sportives",
  "On now": "En ce moment",
  "No channel matches these filters.":
      "Aucune chaîne ne correspond à ces filtres.",
  "No sports channels found in your playlists.":
      "Aucune chaîne sportive trouvée dans vos listes.",
  "Empty list: hold OK on any channel card to add it here.":
      "Liste vide : maintenez OK sur une carte de chaîne pour l'ajouter ici.",
  "OK · Full screen   Hold OK · Pick a channel   Back · Stop":
      "OK · Plein écran   Maintenir OK · Choisir une chaîne   Retour · Arrêter",
  "OK · Preview   Hold OK · Pick a channel or add to a list":
      "OK · Aperçu   Maintenir OK · Choisir une chaîne ou l'ajouter à une liste",
  "See all": "Tout voir",
  "Update automatically": "Mettre à jour automatiquement",
  "On: when an update is due, it runs at launch without asking. Off: the app asks \"Update content now?\" first.":
      "Activé : quand une mise à jour est due, elle se lance au démarrage sans demander. Désactivé : l'appli demande d'abord « Mettre à jour le contenu maintenant ? ».",
  "Open on": "Ouvrir sur",
  "{section}. Where the app opens after starting. With \"Resume last channel in full screen\" on, the channel then plays in the background instead.":
      "{section}. L'écran où l'appli s'ouvre au démarrage. Si « Reprendre la dernière chaîne en plein écran » est activé, la chaîne joue alors en arrière-plan.",
  "Subtitle size": "Taille des sous-titres",
  "Enter a name first": "Saisissez d’abord un nom",
  "Dolby Vision (profile {p}, no HDR10 fallback)":
      "Dolby Vision (profil {p}, sans repli HDR10)",
  "Dolby Vision (profile {p}, HDR10 compatible)":
      "Dolby Vision (profil {p}, compatible HDR10)",
  "Dolby Vision (profile {p}, HLG compatible)":
      "Dolby Vision (profil {p}, compatible HLG)",
  "Dolby Vision (profile {p})": "Dolby Vision (profil {p})",
  "Extra small": "Très petite",
  "Small": "Petite",
  "Normal": "Normale",
  "Large": "Grande",
  "Extra large": "Très grande",
  'Off': "Désactivés",
  'Forced': "Forcés",
  'Online': 'En ligne',
  'Search online subtitles': 'Chercher des sous-titres en ligne',
  'From your add-ons (Settings > Add-ons)':
      'Avec vos modules (Paramètres > Modules)',
  'Online subtitles': 'Sous-titres en ligne',
  'No subtitles found for this title.':
      'Aucun sous-titre trouvé pour ce titre.',
  "Couldn't download that subtitle. Try another.":
      'Impossible de télécharger ce sous-titre. Essayez-en un autre.',
  'Add-ons': 'Modules',
  'Online subtitles in more languages':
      'Sous-titres en ligne dans plus de langues',
  'Remove {name}?': 'Retirer {name} ?',
  "That link isn't a subtitle add-on (only subtitle add-ons are supported).":
      "Ce lien n'est pas un module de sous-titres (seuls ceux-ci sont pris en charge).",
  'That add-on is already in the list.': 'Ce module est déjà dans la liste.',
  '{name} added.': '{name} ajouté.',
  "Add-ons find subtitles online for movies and episodes, in many languages. They are free community services, separate from your provider — VesperTV only uses them for subtitles. Turn one on, then pick \"Search online subtitles\" in the player's Subtitles button.":
      'Les modules trouvent des sous-titres en ligne pour les films et les épisodes, dans de nombreuses langues. Ce sont des services communautaires gratuits, distincts de votre fournisseur — VesperTV ne les utilise que pour les sous-titres. Activez-en un, puis choisissez « Chercher des sous-titres en ligne » dans le bouton Sous-titres du lecteur.',
  'Subtitle add-ons': 'Modules de sous-titres',
  'Subtitles in 60+ languages from OpenSubtitles.org':
      'Sous-titres en plus de 60 langues depuis OpenSubtitles.org',
  'Hold OK to remove': 'Maintenir OK pour retirer',
  'Add an add-on': 'Ajouter un module',
  'Add-on link (ends with manifest.json)':
      'Lien du module (se termine par manifest.json)',
  'Only subtitle add-ons work here. When one is on, the title and episode you are watching are sent to it to find subtitles; nothing else is shared.':
      "Seuls les modules de sous-titres fonctionnent ici. Quand l'un est activé, le titre et l'épisode que vous regardez lui sont envoyés pour trouver des sous-titres ; rien d'autre n'est partagé.",
  'Looking for {language} subtitles…':
      "Recherche de sous-titres en {language}…",
  'No {language} subtitles for this title.':
      "Aucun sous-titre en {language} pour ce titre.",
  'No {language} subtitles online for this title.':
      "Aucun sous-titre en {language} en ligne pour ce titre.",
  'Track {id}': "Piste {id}",
  'Audio {n}': "Audio {n}",
  'Audio Track': "Piste audio",
  'Audio track': "Piste audio",

  // ── Catalog / browse ─────────────────────────────────────────────────
  'Sort': "Trier",
  'Default': "Par défaut",
  'A to Z': "A à Z",
  'Z to A': "Z à A",
  'Rating (high to low)': "Note (décroissante)",
  'Date added/updated': "Date d'ajout/MAJ",
  'Fetching TMDB release dates... {done}/{total}':
      "Récupération des dates de sortie TMDB… {done}/{total}",
  'Added to Favorites': "Ajouté aux favoris",
  'Removed from Favorites': "Retiré des favoris",
  'No items in this group.': "Rien dans ce groupe.",
  'Re-checks your M3U playlist URL(s) for new content.':
      "Revérifie l'URL de vos listes M3U pour du nouveau contenu.",
  'Set your playlist source in Settings first.':
      "Configurez d'abord votre liste dans les Paramètres.",
  'Continue Watching': "Reprendre l'écoute",
  'Search': "Recherche",
  'Update content': "MAJ du contenu",
  'Update EPG now': "MAJ du guide",
  'Settings': "Paramètres",
  'No TV shows found. Pick a category on the left.':
      "Aucune série trouvée. Choisissez une catégorie à gauche.",
  'No channels found.': "Aucune chaîne trouvée.",
  'Loading playlist...': "Chargement de la liste…",
  'Failed to load playlist.': "Échec du chargement de la liste.",
  'Open Settings': "Ouvrir les paramètres",
  '{p}% watched': "{p} % vu",
  'Resume': "Reprendre",
  'Play': "Lire",
  'Restart': "Recommencer",
  'Failed to load episodes.': "Échec du chargement des épisodes.",
  'No episodes found.': "Aucun épisode trouvé.",
  'Season {season}': "Saison {season}",
  'Expand catalog': "Catalogue complet",
  'Browse': "Parcourir",
  'Playlist': "Liste",
  'Previous': "Précédent",
  'Next': "Suivant",
  'Loading...': "Chargement…",
  'Loading…': "Chargement…",
  'No recently added movies yet': "Aucun film ajouté récemment",
  'Loading movie categories...': "Chargement des catégories de films…",
  'No recently added shows yet': "Aucune série ajoutée récemment",
  'Loading TV show categories...': "Chargement des catégories de séries…",
  "What's New": "Nouveautés",

  // ── Search ───────────────────────────────────────────────────────────
  'Switch Profile': "Changer de profil",
  'Restricted': "Restreint",
  'Search everything...': "Tout rechercher…",
  'Search everything... (press OK to type)':
      "Tout rechercher… (OK pour écrire)",
  'Still loading the full catalog in the background ({warmCatalogDone}/{warmCatalogTotal} categories) — some results may not show up yet.':
      "Le catalogue complet charge encore en arrière-plan ({warmCatalogDone}/{warmCatalogTotal} catégories) — certains résultats peuvent manquer.",
  'Search Live TV, Movies & TV Shows':
      "Rechercher télé en direct, films et séries",
  'Recent searches': "Recherches récentes",
  'Clear': "Effacer",
  'Live TV': "Télé en direct",
  'Movies': "Films",
  'TV Shows': "Séries",
  'Nothing found': "Aucun résultat",

  // ── Sports ───────────────────────────────────────────────────────────
  'Sports': "Sports",
  'this team': "cette équipe",
  'My Teams': "Mes équipes",
  'Last channels': "Dernières chaînes",
  '◀ ▶ tabs  ·  OK to watch  ·  Back to close':
      "◀ ▶ onglets  ·  OK pour regarder  ·  Retour pour fermer",
  'None of your teams play today.':
      "Aucune de vos équipes ne joue aujourd'hui.",
  'Follow teams from {tab} > Standings to see them here.':
      "Suivez des équipes dans {tab} > Classement pour les voir ici.",
  'No games from your leagues are live right now.':
      "Aucun match de vos ligues n'est en direct pour l'instant.",
  'Hold OK on a team to unfollow · on a game to pick the channel':
      "Maintenir OK sur une équipe pour ne plus la suivre · sur un match pour choisir la chaîne",
  'Add team': "Ajouter une équipe",
  'Follow one from Standings': "Suivre depuis le classement",
  'Could not load': "Chargement impossible",
  'Follow your teams to see them here': "Suivez vos équipes pour les voir ici",
  'Follow another team': "Suivre une autre équipe",
  'Add team opens Standings: hold OK on a team to follow it.':
      "« Ajouter une équipe » ouvre le classement : maintenez OK sur une équipe pour la suivre.",
  'This team could not be loaded. Check the connection.':
      "Impossible de charger cette équipe. Vérifiez la connexion.",
  'Next 2 weeks': "2 prochaines semaines",
  'No games in the next two weeks.':
      "Aucun match dans les deux prochaines semaines.",
  'vs': "c.",
  'at': "@",
  'Today {time}': "Auj. {time}",
  'Tomorrow {time}': "Demain {time}",
  'Last game: {opponent} · Final': "Dern. match : {opponent} · Fin",
  'Last game: {result} {mine}-{other} {opponent}':
      "Dern. match : {result} {mine}-{other} {opponent}",
  'LIVE': "EN DIRECT",
  'Looking…': "Recherche…",
  'TEAM': "ÉQUIPE",
  'Later today': "Plus tard aujourd'hui",
  'Tomorrow': "Demain",
  'Not played': "Non joués",
  'Scheduled': "À venir",
  'Live now': "En direct",
  'Final': "Fin",
  'All': "Tout",
  'Edit leagues': "Ligues",
  'Scores hidden': "Pointages cachés",
  'Scores shown': "Pointages affichés",
  'Yesterday': "Hier",
  'Today': "Aujourd'hui",
  'Day': "Jour",
  'OK: watch  ·  OK again: full screen  ·  Hold OK: stats  ·  ▼ all games':
      "OK : regarder  ·  OK de nouveau : plein écran  ·  Maintenir OK : stats  ·  ▼ tous les matchs",
  'OK again on a game: full screen  ·  ▶❚❚: stop':
      "OK de nouveau sur un match : plein écran  ·  ▶❚❚ : arrêter",
  'Standings': "Classement",
  '{name} standings': "Classement {name}",
  '{name} championship': "Championnat {name}",
  'No games on this day for your leagues':
      "Aucun match ce jour-là dans vos ligues",
  'Try another day, or add leagues with Edit leagues.':
      "Essayez un autre jour ou ajoutez des ligues avec le bouton Ligues.",
  'Live now  {count}': "En direct  {count}",
  'Live': "En direct",
  'Starts in {p}{p2}m': "Dans {p}{p2} min",
  'Looking for the channel…': "Recherche de la chaîne…",
  'No channel found — OK to pick one':
      "Aucune chaîne trouvée — OK pour en choisir une",
  'Hold OK to pick or swap the channel':
      "Maintenir OK : choisir/changer la chaîne",
  'Hold OK: pick the channel  ·  ▶❚❚: watch here':
      "Maintenir OK : choisir la chaîne  ·  ▶❚❚ : regarder ici",
  'Tap the game again: full screen  ·  Back: stop':
      "Touchez le match à nouveau : plein écran  ·  Retour : arrêter",
  'Tap: watch here  ·  Hold: pick the channel':
      "Toucher : regarder ici  ·  Maintenir : choisir la chaîne",
  'Play here': "Lire ici",
  '{channel} · plays at the top of {tab}': "{channel} · joue en haut de {tab}",
  '▶❚❚: watch this game  ·  Back: playing game':
      "▶❚❚ : regarder ce match  ·  Retour : match en cours",
  'OK: full screen  ·  ▶❚❚ or Back: stop':
      "OK : plein écran  ·  ▶❚❚ ou Retour : arrêter",
  'Still looking for channels…': "Recherche de chaînes en cours…",
  'No channel found for this game': "Aucune chaîne trouvée pour ce match",
  'On {matches} channel{s}': "Sur {matches} chaîne{s}",
  'Pick the channel': "Choisir la chaîne",
  'Choose a different channel': "Choisir une autre chaîne",
  'Search your channels — it can be remembered for this game or team':
      "Cherchez dans vos chaînes — le choix peut être retenu pour ce match ou cette équipe",
  'Forget my pick': "Oublier mon choix",
  'Go back to the automatic match': "Revenir au choix automatique",
  'Remember this channel?': "Retenir cette chaîne?",
  'Just this game': "Ce match seulement",
  'Best for channels named after one game':
      "Idéal pour les chaînes nommées d'après un match",
  'Always for the {shortName}': "Toujours pour les {shortName}",
  'Best for a regular channel, like a regional network':
      "Idéal pour une chaîne régulière, comme un réseau régional",
  'Leagues': "Ligues",
  'Save': "Enregistrer",
  'Pick the channel for {title}': "Choisir la chaîne pour {title}",
  'Search channels': "Rechercher des chaînes",
  'No channels match "{query}"': "Aucune chaîne ne correspond à « {query} »",
  '{results}{p} channels': "{results}{p} chaînes",
  '{group} · Now: {now}': "{group} · En cours : {now}",
  'Preseason': "Présaison",
  'Pick a league above, then hold OK on a team to follow it. Back returns to My Teams.':
      "Choisissez une ligue en haut, puis maintenez OK sur une équipe pour la suivre. Retour ramène à Mes équipes.",
  'Standings could not be loaded. Check the connection.':
      "Impossible de charger le classement. Vérifiez la connexion.",
  'switch conference': "changer d'association",
  'switch table': "changer de tableau",
  'Hold OK on a team to follow it (My Teams)':
      "Maintenir OK sur une équipe pour la suivre (Mes équipes)",
  'Your pick': "Votre choix",
  'Found by its name': "Trouvée par son nom",
  'Found in the guide': "Trouvée dans le guide",
  "Team's channel, no guide listing": "Chaîne de l'équipe, pas dans le guide",
  "Broadcaster, no guide listing": "Diffuseur, pas dans le guide",
  "Only on a hidden channel": "Seulement sur une chaîne masquée",
  "Not in your guide yet": "Pas encore dans votre guide",
  "On a hidden channel — OK to pick one":
      "Sur une chaîne masquée — OK pour en choisir une",
  "Not in your guide yet — OK to pick one":
      "Pas encore dans votre guide — OK pour en choisir une",
  "Only found on {channel}, which is hidden in your lists.":
      "Trouvé seulement sur {channel}, qui est masquée dans vos listes.",
  "Your guide doesn't cover this game's time yet. Update the guide closer to the game.":
      "Votre guide ne couvre pas encore l'heure de ce match. Mettez le guide à jour plus près du match.",
  "No channel name or guide listing names this game.":
      "Aucun nom de chaîne ni programme du guide ne mentionne ce match.",
  'Some scores could not be loaded. Check the connection.':
      "Certains pointages n'ont pas pu être chargés. Vérifiez la connexion.",
  'Unfollow': "Ne plus suivre",
  'Follow': "Suivre",
  'Remove from My Teams': "Retirer de Mes équipes",
  'Add to My Teams — their games show first in {tab}':
      "Ajouter à Mes équipes — leurs matchs s'affichent en premier dans {tab}",
  // Results (W/L/D = victory/defeat/draw) and standings columns.
  'W': "V",
  'L': "D",
  'D': "N",
  'T': "N",
  'GP': "PJ",
  'GD': "DIFF",
  'PTS': "PTS",
  'OTL': "DP",
  'DIFF': "DIFF",
  'STRK': "SÉQ",
  'L10': "10 DER",
  'REC': "V-D",
  'PF': "PP",
  'PA': "PC",
  'HOME': "DOM",
  'AWAY': "ÉTR",
  'PCT': "PCT",
  'GB': "DIFF",

  // ── TV home ──────────────────────────────────────────────────────────
  'TV': "Télé",
  'Favorites': "Favoris",
  'Favourites': "Favoris",
  'Remove from Favourites': "Retirer des favoris",
  'Add to Favourites': "Ajouter aux favoris",
  'Cancel Hide': "Annuler le masquage",
  'Hide Group': "Masquer le groupe",
  'Move Up / Down': "Monter / descendre",
  "Show": "Afficher",
  "Hide": "Masquer",
  "Hidden here · {n} groups": "Masquée ici · {n} groupes",
  "At least one playlist stays shown.": "Au moins une playlist reste affichée.",
  "{name} hidden in {tab}": "{name} masquée dans {tab}",
  "{name} shown in {tab}": "{name} affichée dans {tab}",
  "Playlists": "Playlists",
  "Jump to playlist": "Aller à la playlist",
  "{n} groups": "{n} groupes",
  "Background video": "Vidéo en arrière-plan",
  "Mute": "Couper le son",
  "Unmute": "Rétablir le son",
  "Show under Other": "Afficher dans Autre",
  "On: this source only appears behind the Other genre filter (Movies and TV Shows). Off: in the main rows. Press Refresh in Media Hub after changing this.":
      "Activé : cette source n'apparaît que derrière le filtre de genre Autre (Films et Séries). Désactivé : dans les rangées principales. Appuyez sur Actualiser dans Media Hub après un changement.",
  "Use the Other filter in Media Hub > Movies / TV Shows > Genre to see this source.":
      "Utilisez le filtre Autre dans Media Hub > Films / Séries > Genre pour voir cette source.",
  "Back to main": "Retour au principal",
  "Compatibility video": "Vidéo compatible",
  "Turn this on if the picture shows twice, in the wrong size or as coloured stripes (older Fire TV sticks). Applies from the next channel. On by default on Android 7 and older.":
      "Activez ceci si l'image s'affiche en double, à la mauvaise taille ou en rayures de couleur (anciennes clés Fire TV). S'applique à partir de la chaîne suivante. Activé par défaut sur Android 7 et versions antérieures.",
  "Hide the live picture behind other pages":
      "Masquer l'image en direct derrière les autres pages",
  "A live channel keeps playing behind {tab}, Settings and Search. Some Fire TV sticks keep showing its picture on top of those pages. Turn this on if that happens: the sound keeps going, only the picture is hidden until you go back. Updating the device's software (Fire TV: Settings > My Fire TV > About > Check for Updates) may fix it too.":
      "Une chaîne en direct continue derrière {tab}, Paramètres et Recherche. Certaines clés Fire TV continuent d'afficher son image par-dessus ces pages. Activez cette option si cela arrive : le son continue, seule l'image est masquée jusqu'à votre retour. Mettre à jour le logiciel de l'appareil (Fire TV : Paramètres > Ma Fire TV > À propos > Rechercher des mises à jour) peut aussi régler le problème.",
  'Go to row': "Aller à la rangée",
  "Typing a server address and password with a remote is painful. Scan this code with your phone camera and sign in there — the details appear here for you to check and connect.":
      "Taper une adresse de serveur et un mot de passe avec une télécommande est pénible. Scannez ce code avec l'appareil photo de votre téléphone et connectez-vous là-bas — les informations apparaissent ici pour que vous les vérifiiez.",
  "Check the details here, then press Connect.":
      "Vérifiez les informations ici, puis appuyez sur Connecter.",
  "{n} other catalogs": "{n} autres catalogues",
  "Use the Other filter in Media Hub > Movies > Genre to see this content.":
      "Utilisez le filtre Autres dans Media Hub > Films > Genre pour voir ce contenu.",
  "Backup & restore": "Sauvegarde et restauration",
  "Save everything to a file on this device":
      "Tout enregistrer dans un fichier sur cet appareil",
  "Back up now": "Sauvegarder maintenant",
  "Playlists, favourites, profiles, progress and settings, saved to {path}":
      "Playlists, favoris, profils, progression et réglages, enregistrés dans {path}",
  "Automatic backup": "Sauvegarde automatique",
  "Once a week, when VesperTV starts. Keeps the last {n}.":
      "Une fois par semaine, au démarrage de VesperTV. Garde les {n} dernières.",
  "Restore from a file": "Restaurer depuis un fichier",
  "Pick a backup file, e.g. after reinstalling VesperTV":
      "Choisissez un fichier de sauvegarde, par exemple après avoir réinstallé VesperTV",
  "Backups": "Sauvegardes",
  "No backups yet.": "Aucune sauvegarde pour l'instant.",
  "Backups include your playlist logins. Keep the files private.":
      "Les sauvegardes contiennent les identifiants de vos playlists. Gardez ces fichiers privés.",
  "Manual": "Manuelle",
  "Restore this backup": "Restaurer cette sauvegarde",
  "Restore": "Restaurer",
  "Restore backup?": "Restaurer la sauvegarde ?",
  "Everything on this device (playlists, favourites, profiles, settings) is replaced by the backup from {from}. Your current setup is saved as an automatic backup first. VesperTV closes afterwards.":
      "Tout ce qui est sur cet appareil (playlists, favoris, profils, réglages) est remplacé par la sauvegarde du {from}. Votre configuration actuelle est d'abord enregistrée comme sauvegarde automatique. VesperTV se ferme ensuite.",
  "the chosen file": "le fichier choisi",
  "Backup restored": "Sauvegarde restaurée",
  "Backup saved to {path}": "Sauvegarde enregistrée dans {path}",
  "Backup failed: {error}": "Échec de la sauvegarde : {error}",
  "VesperTV needs storage access to save backups.":
      "VesperTV a besoin de l'accès au stockage pour enregistrer les sauvegardes.",
  "Couldn't read the backup folder: {error}":
      "Impossible de lire le dossier de sauvegarde : {error}",
  "Couldn't read this backup: {error}":
      "Impossible de lire cette sauvegarde : {error}",
  "Couldn't delete this backup.": "Impossible de supprimer cette sauvegarde.",
  "This device has no file picker. Copy the backup into {path} on this device instead.":
      "Cet appareil n'a pas de sélecteur de fichiers. Copiez plutôt la sauvegarde dans {path} sur cet appareil.",
  "This file is not a VesperTV backup.":
      "Ce fichier n'est pas une sauvegarde VesperTV.",
  "Up / Down moves {name}. OK when done.":
      "Haut / Bas déplace {name}. OK pour terminer.",
  "Mix playlists in Favourites": "Mélanger les playlists dans les favoris",
  "TV, Movies and TV Shows favourites from every playlist in one A-Z list, instead of one list per playlist.":
      "Les favoris TV, Films et Séries de toutes les playlists dans une seule liste de A à Z, au lieu d'une liste par playlist.",
  'Move to Top': "Mettre en haut",
  'Unhide this channel': "Réafficher cette chaîne",
  'Hide this channel': "Masquer cette chaîne",
  'Double': "Double",
  'for groups': "pour les groupes",
  'Exit and free up this login?': "Quitter et libérer cette connexion?",
  'This disconnects your login here so it can be used on another device, then fully closes VesperTV. Your channels/movies will need to reload next time you open it.':
      "Ça déconnecte votre compte ici pour qu'il serve sur un autre appareil, puis ferme complètement VesperTV. Vos chaînes et films devront recharger à la prochaine ouverture.",
  'Exit': "Quitter",
  'Exit {appName}?': "Quitter {appName}?",
  'Are you sure you want to exit {appName}?':
      "Voulez-vous vraiment quitter {appName}?",
  'Stay': "Rester",
  'History': "Historique",
  'No channels watched yet.': "Aucune chaîne regardée pour l'instant.",
  'Update Content': "MAJ du contenu",
  'Minimize': "Réduire",
  'Close': "Fermer",
  'Disable and exit': "Désactiver et quitter",
  'Long-press a group elsewhere to favorite the whole thing.':
      "Maintenez OK sur un groupe ailleurs pour l'ajouter en entier aux favoris.",
  'Nothing playing': "Rien en lecture",
  'Click to resume': "Cliquer pour reprendre",
  'Filter channels in this group...': "Filtrer les chaînes de ce groupe…",
  'Close filter': "Fermer le filtre",
  'Hidden — find it again in Settings > Playlist Manager > Hidden Channels':
      "Masquée — retrouvez-la dans Paramètres > Gestion des listes > Chaînes masquées",
  'Unhidden': "Réaffichée",
  'No favorited movies or TV shows yet.\nHold Select on a poster to add one.':
      "Aucun film ni série en favoris.\nMaintenez OK sur une affiche pour en ajouter.",
  'No favorited movies yet.': "Aucun film en favoris.",
  'No favorited TV shows yet.': "Aucune série en favoris.",
  'No favorite channels yet — press Down while watching one to add it.':
      "Aucune chaîne favorite — appuyez sur Bas pendant l'écoute pour en ajouter une.",
  'Updating…': "MAJ en cours…",
  'No program data': "Aucun horaire",
  'No program data available': "Aucun horaire disponible",
  'Next: {title} ({p})': "Ensuite : {title} ({p})",
  'Focus a program to see details':
      "Sélectionnez une émission pour voir les détails",
  'Space': "Espace",
  'Loading EPG…': "Chargement du guide…",

  // ── Welcome ──────────────────────────────────────────────────────────
  'Hey beautiful Human,': "Salut, bel humain,",
  'Hey beautiful Human': "Salut, bel humain",
  'Welcome to VesperTV': "Bienvenue dans VesperTV",
  'Add your first playlist?': "Ajouter votre première liste?",
  'Add a playlist to kick things off, or skip for now if you just want to browse and discover the app without content.':
      "Ajoutez une liste pour commencer, ou passez pour l'instant si vous voulez juste découvrir l'appli sans contenu.",

  // ── Add playlist ─────────────────────────────────────────────────────
  'Add Playlist': "Ajouter une liste",
  'Paste some text first.': "Collez d'abord du texte.",
  "Couldn't find anything usable in that text.":
      "Rien d'utilisable dans ce texte.",
  'Received from your phone — check the details, then press Add Playlist.':
      "Reçu de votre téléphone — vérifiez les infos, puis appuyez sur « Ajouter une liste ».",
  'Scan the code with your phone and send the form first.':
      "Scannez d'abord le code avec votre téléphone et envoyez le formulaire.",
  'Playlist name is required.': "Le nom de la liste est requis.",
  'Server, username, and password are all required.':
      "Serveur, utilisateur et mot de passe sont requis.",
  'M3U playlist URL is required.': "L'URL de la liste M3U est requise.",
  'Playlist updated.': "Liste mise à jour.",
  'Playlist added.': "Liste ajoutée.",
  'Download content': "Télécharger le contenu",
  'This provider has a large catalog. Download everything in the background, or choose which groups to include first?':
      "Ce fournisseur a un gros catalogue. Tout télécharger en arrière-plan, ou choisir d'abord les groupes à inclure?",
  'Choose Groups First': "Choisir les groupes",
  'Download All': "Tout télécharger",
  'Edit Playlist': "Modifier la liste",
  'Playlist source': "Source de la liste",
  'M3U URL': "URL M3U",
  'Xtream Codes': "Xtream Codes",
  'Smart Add': "Ajout intelligent",
  'From phone': "Du téléphone",
  'Playlist name': "Nom de la liste",
  'Name': "Nom",
  'e.g. My Provider, or 8kStrong': "p. ex. Mon fournisseur, ou 8kStrong",
  'M3U Playlist URL': "URL de la liste M3U",
  'EPG (XMLTV) URL': "URL du guide (XMLTV)",
  'Paste the message your provider sent you — we\'ll pull out the server, username, and password.':
      "Collez le message envoyé par votre fournisseur — on en tire le serveur, l'utilisateur et le mot de passe.",
  'Paste provider message': "Coller le message du fournisseur",
  'Parse': "Analyser",
  'Confirm the server': "Confirmer le serveur",
  'No server URL found in that text — enter it below.':
      "Aucune URL de serveur dans ce texte — entrez-la ci-dessous.",
  'Server URL (e.g. http://host:port)':
      "URL du serveur (p. ex. http://hote:port)",
  'Username': "Utilisateur",
  'Password': "Mot de passe",
  'Custom EPG (XMLTV) URL — optional':
      "URL de guide perso (XMLTV) — facultatif",
  'Leave blank to use the panel\'s own xmltv.php. Set this if your provider\'s EPG is empty or unreliable (e.g. a third-party feed like EPGgenius) — it only fills in a channel if that feed\'s ids match this panel\'s.':
      "Laissez vide pour utiliser le xmltv.php du panneau. À remplir si le guide de votre fournisseur est vide ou peu fiable (p. ex. une source tierce comme EPGgenius) — une chaîne n'est remplie que si les identifiants de cette source correspondent à ceux du panneau.",
  'Paste different text': "Coller un autre texte",
  'Status': "État",
  'Failed to add playlist: {p}': "Échec de l'ajout de la liste : {p}",
  'Save Changes': "Enregistrer",
  'Fill in the form on the left, then press {p} above.':
      "Remplissez le formulaire à gauche, puis appuyez sur « {p} » en haut.",
  'Unexpected Xtream API response': "Réponse inattendue de l'API Xtream",
  'Invalid Xtream username/password':
      "Utilisateur ou mot de passe Xtream invalide",
  'Xtream account is not active (status: {status})':
      "Le compte Xtream n'est pas actif (état : {status})",

  // ── Phone pairing ────────────────────────────────────────────────────
  'Code expired': "Code expiré",
  'Add from your phone': "Ajouter avec votre téléphone",
  'Typing a long password with a remote is painful. Scan this code with your phone camera and fill in the form there — it appears here for you to check and add.':
      "Taper un long mot de passe avec une télécommande, c'est pénible. Scannez ce code avec l'appareil photo de votre téléphone et remplissez le formulaire — il apparaît ici pour vérification et ajout.",
  'Scan with your phone (mobile data is fine).':
      "Scannez avec votre téléphone (les données mobiles fonctionnent).",
  'Connect your phone to the same Wi-Fi as this TV, then scan.':
      "Connectez votre téléphone au même Wi-Fi que cette télé, puis scannez.",
  'Fill in the form and tap Send to TV.':
      "Remplissez le formulaire et touchez « Send to TV ».",
  'Check the details here, then press Add Playlist.':
      "Vérifiez les infos ici, puis appuyez sur « Ajouter une liste ».",
  'Waiting for your phone…': "En attente de votre téléphone…",
  'Or open on the phone:': "Ou ouvrez sur le téléphone :",
  'Your details are encrypted on the phone; the relay only passes along scrambled data and deletes it.':
      "Vos infos sont chiffrées sur le téléphone; le relais ne fait que transmettre des données brouillées, puis les supprime.",
  'New code': "Nouveau code",
  'Phone on this Wi-Fi? Use the Wi-Fi code':
      "Téléphone sur ce Wi-Fi? Utilisez le code Wi-Fi",
  'Phone not on this Wi-Fi? Use the other code':
      "Téléphone pas sur ce Wi-Fi? Utilisez l'autre code",

  // ── Channel linking / EPG matching ───────────────────────────────────
  'Add and enable a second playlist first — a link connects a channel on one playlist to its equivalent on another.':
      "Ajoutez et activez d'abord une 2e liste — un lien relie une chaîne d'une liste à son équivalent dans une autre.",
  'Auto-Pair Channels': "Associer auto.",
  'Unpair Channels': "Dissocier",
  'Reviewing {reviewFilter} auto-paired channel{s} — type to search all instead':
      "Révision de {reviewFilter} chaîne{s} associée{s} auto. — tapez pour tout chercher",
  'Search your channels': "Rechercher vos chaînes",
  'Not linked': "Non liée",
  'Linked channel no longer available': "La chaîne liée n'est plus disponible",
  'Linked to {p}: {name}': "Liée à {p} : {name}",
  'Clear link': "Retirer le lien",
  'Link "{name}"': "Lier « {name} »",
  'Search other playlists\' channels':
      "Chercher dans les chaînes des autres listes",
  'No matches.': "Aucune correspondance.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" first so there\'s a channel directory to match against.':
      "Aucun guide chargé pendant cette session — lancez d'abord « MAJ du guide » pour avoir un répertoire de chaînes.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" above first so there\'s a channel directory to search.':
      "Aucun guide chargé pendant cette session — lancez d'abord « MAJ du guide » plus haut pour avoir un répertoire de chaînes.",
  'Assigned: {p}': "Assignée : {p}",
  'Matched automatically': "Associée automatiquement",
  'Clear assignment': "Retirer l'assignation",
  'Assign "{channelName}"': "Assigner « {channelName} »",
  'Search the EPG feed\'s channels': "Chercher dans les chaînes du guide",
  'No EPG feed has been loaded yet this app session — go back and run "Update EPG Now" first.':
      "Aucun guide chargé pendant cette session — revenez en arrière et lancez d'abord « MAJ du guide ».",
  'Now: {title}': "En cours : {title}",
  'No current program data': "Aucune émission en cours",
  'Channels are pairing, please wait…':
      "Association des chaînes, veuillez patienter…",
  'No new matches found — anything still unmatched needs a manual pick.':
      "Aucune nouvelle correspondance — le reste doit être choisi à la main.",
  'Paired {paired} channel{s} automatically.':
      "{paired} chaîne{s} associée{s} automatiquement.",
  'Review': "Réviser",
  'Continue': "Continuer",
  'Nothing was auto-paired — there\'s nothing to undo.':
      "Rien n'a été associé auto. — rien à annuler.",
  'Undo {autoPairedCount} automatic pairing{s}? Anything you\'ve set by hand is kept.':
      "Annuler {autoPairedCount} association{s} automatique{s}? Ce que vous avez fait à la main est conservé.",
  'Unpair': "Dissocier",

  // ── Check for updates ────────────────────────────────────────────────
  'Couldn\'t open the download link.':
      "Impossible d'ouvrir le lien de téléchargement.",
  'Allow installing updates': "Autoriser l'installation des MAJ",
  'Android needs one-time permission for VesperTV to install an update it downloaded. The next screen is Android\'s own settings — turn the toggle on, then come back here and press Install again.':
      "Android doit autoriser une fois VesperTV à installer une MAJ téléchargée. L'écran suivant est dans les paramètres d'Android — activez l'option, puis revenez ici et appuyez de nouveau sur Installer.",
  'Check for Updates': "Vérifier les MAJ",
  'Current version: —': "Version actuelle : —",
  'Current version: {currentVersion}': "Version actuelle : {currentVersion}",
  'Checking...': "Vérification…",
  'You\'re on the latest version.': "Vous avez la dernière version.",
  'Check Again': "Revérifier",
  'Version {version} is available': "La version {version} est disponible",
  'Open Download Page': "Ouvrir la page de téléchargement",
  'Opens in your browser — unzip the download and run VesperTV.exe to update, replacing the old folder.':
      "S'ouvre dans votre navigateur — décompressez le fichier et lancez VesperTV.exe pour mettre à jour, en remplaçant l'ancien dossier.",
  'Download & Install': "Télécharger et installer",
  'Downloading update... {p}%': "Téléchargement de la MAJ… {p} %",
  'Download complete.': "Téléchargement terminé.",
  'Install': "Installer",
  'Android will ask you to confirm the install — that\'s normal, not every app can skip it.':
      "Android va vous demander de confirmer l'installation — c'est normal, toutes les applis ne peuvent pas l'éviter.",
  'Something went wrong: {p}': "Un problème est survenu : {p}",
  'unknown error': "erreur inconnue",
  'Try Again': "Réessayer",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minute.':
      "GitHub limite temporairement les vérifications de MAJ depuis ce réseau — réessayez dans environ {n} minute.",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minutes.':
      "GitHub limite temporairement les vérifications de MAJ depuis ce réseau — réessayez dans environ {n} minutes.",
  'GitHub is temporarily rate-limiting update checks from this network — try again shortly.':
      "GitHub limite temporairement les vérifications de MAJ depuis ce réseau — réessayez bientôt.",

  // ── EPG settings ─────────────────────────────────────────────────────
  'No EPG URL set yet — add a playlist first.':
      "Aucune URL de guide — ajoutez d'abord une liste.",
  'Cache cleared.': "Cache vidé.",
  'EPG': "Guide (EPG)",
  'General': "Général",
  'EPG Matching': "Assoc. du guide",
  'Channel Pairing': "Assoc. de chaînes",
  'Auto-refresh interval': "Intervalle de MAJ auto.",
  '{p} hours': "{p} heures",
  'EPG never updated': "Guide jamais mis à jour",
  'EPG last updated: {p}': "Dernière MAJ du guide : {p}",
  'Update EPG Now': "MAJ du guide",
  'Clear Cache': "Vider le cache",
  'Clears the cached EPG and catalog data — playlist source, favorites, and group visibility are kept.':
      "Vide le guide et le catalogue en cache — la source des listes, les favoris et la visibilité des groupes sont gardés.",
  'Fixes a channel with no program data by manually assigning it to an entry in the loaded EPG feed — useful when a provider\'s own id doesn\'t match a third-party source.':
      "Corrige une chaîne sans horaire en l'assignant à la main à une entrée du guide chargé — utile quand l'identifiant du fournisseur ne correspond pas à une source tierce.",
  'Links a channel on one playlist to its equivalent on another. If a live channel fails to load, or you switch to it yourself from the player, playback can fall back to the paired channel on the other playlist instead.':
      "Relie une chaîne d'une liste à son équivalent dans une autre. Si une chaîne en direct ne charge pas, ou si vous changez vous-même depuis le lecteur, la lecture peut basculer sur la chaîne associée de l'autre liste.",

  // ── General settings ─────────────────────────────────────────────────
  'Clear search & channel history?':
      "Effacer l'historique de recherche et des chaînes?",
  'Removes your recent searches and the History list of live channels.':
      "Supprime vos recherches récentes et l'historique des chaînes en direct.",
  'Search and channel history cleared.':
      "Historique de recherche et des chaînes effacé.",
  'Clear Movies & TV Shows history?':
      "Effacer l'historique des films et séries?",
  'Removes Continue Watching and the saved progress of every movie and episode.':
      "Supprime Reprendre l'écoute et la progression de chaque film et épisode.",
  'Movies & TV Shows history cleared.':
      "Historique des films et séries effacé.",
  'Language': "Langue",
  'Follows the device language': "Suit la langue de l'appareil",
  'Automatic': "Automatique",
  'Startup': "Démarrage",
  'Resume last channel in full screen':
      "Reprendre la dernière chaîne en plein écran",
  'Opens the last live channel full screen after the splash.':
      "Ouvre la dernière chaîne en direct en plein écran après le démarrage.",
  'Resume last channel with the guide open':
      "Reprendre la dernière chaîne avec le guide ouvert",
  'Plays the last live channel in the small preview, with the channel list.':
      "Lit la dernière chaîne en direct dans le petit aperçu, avec la liste des chaînes.",
  'Both off: nothing plays at startup (a "Hold > to resume" reminder instead).':
      "Les deux désactivés : rien ne joue au démarrage (un rappel « Maintenir > pour reprendre » à la place).",
  'Tabs': "Onglets",
  'Hide Movies and TV Shows': "Masquer Films et Séries",
  'Removes both tabs and their search results, e.g. if you watch movies and shows elsewhere.':
      "Retire les deux onglets et leurs résultats de recherche, par ex. si vous regardez films et séries ailleurs.",
  'Favorite channels are in the TV tab, under Favourites.':
      "Les chaînes favorites sont dans l'onglet TV, sous Favoris.",
  'Show the Multiview tip': "Afficher le conseil Multivue",
  'The connections reminder shown when opening Multiview.':
      "Le rappel sur les connexions à l'ouverture de la Multivue.",
  'Resume reminder': "Rappel de reprise",
  'Show the "Hold > to resume" reminder':
      "Afficher le rappel « Maintenir > pour reprendre »",
  'The pill at the bottom while a channel plays in the background. Off: hidden.':
      "La pastille en bas quand une chaîne joue en arrière-plan. Désactivé : cachée.",
  'The pill at the bottom while a channel plays in the background. Off: hidden — holding Right still resumes.':
      "La pastille en bas quand une chaîne joue en arrière-plan. Désactivé : cachée — maintenir Droite reprend quand même.",
  'Clear search & channel history':
      "Effacer l'historique de recherche et des chaînes",
  'Recent searches and the live channel History':
      "Recherches récentes et historique des chaînes en direct",
  'Clear Movies & TV Shows history': "Effacer l'historique des films et séries",
  'Continue Watching and saved progress':
      "« Reprendre l'écoute » et progression sauvegardée",

  // ── Group management / hidden channels ───────────────────────────────
  'Leave group selection?': "Quitter la sélection des groupes?",
  'Your show/hide choices are saved, and anything still visible will start downloading — same as pressing Done.':
      "Vos choix afficher/masquer sont gardés et tout ce qui reste visible commence à télécharger — comme en appuyant sur Terminé.",
  'Leave': "Quitter",
  'Save playlist?': "Enregistrer la liste?",
  'Your playlist will be saved with the selected groups. You can always add or remove groups later in Settings > Group Management.':
      "Votre liste sera enregistrée avec les groupes choisis. Vous pourrez toujours en ajouter ou en retirer dans Paramètres > Gestion des groupes.",
  'Confirm': "Confirmer",
  'Group Management': "Gestion des groupes",
  'Done': "Terminé",
  'If you are done selecting your groups, press Confirm below.\n\nIf you are not done yet, press Left to go back to your categories.':
      "Si vous avez fini de choisir vos groupes, appuyez sur Confirmer ci-dessous.\n\nSinon, appuyez sur Gauche pour revenir à vos catégories.",
  'No categories yet — load a playlist first.':
      "Aucune catégorie — chargez d'abord une liste.",
  'Search groups (starts with)': 'Rechercher des groupes (commence par)',
  '{shown} of {total} groups': '{shown} groupes sur {total}',
  'Show results': 'Afficher les résultats',
  'Hide results': 'Masquer les résultats',
  'No groups start with "{query}".':
      'Aucun groupe ne commence par « {query} ».',
  'Show All': "Tout afficher",
  'Hide All': "Tout masquer",
  'Hidden channels': "Chaînes masquées",
  'No channels are individually hidden. Hide one from its row in the Live TV list.':
      "Aucune chaîne masquée individuellement. Masquez-en une depuis sa ligne dans la liste Télé en direct.",
  'Unhide': "Réafficher",
  'Show group': "Afficher le groupe",
  'Hide group': "Masquer le groupe",

  // ── Playlist manager / priority ──────────────────────────────────────
  'Playlist Manager': "Gestion des listes",
  'Playlist Priority': "Priorité des listes",
  'Which playlist\'s groups show first, per tab':
      "Quelle liste affiche ses groupes en premier, par onglet",
  'No playlists yet — tap "Add Playlist" above to get started.':
      "Aucune liste — appuyez sur « Ajouter une liste » plus haut pour commencer.",
  'Delete playlist?': "Supprimer la liste?",
  'This removes "{name}"\'s login and cached catalog from this device. Its favorited channels/movies stay in your shared Favorites list, but will no longer play unless you add this playlist back.':
      "Ça retire la connexion et le catalogue en cache de « {name} » de cet appareil. Ses chaînes et films favoris restent dans vos Favoris, mais ne joueront plus tant que vous n'aurez pas rajouté cette liste.",
  'Delete': "Supprimer",
  'Add backup server': "Ajouter un serveur de secours",
  'The full address, exactly like the main one — for example http://backup.example.com:8080':
      "L'adresse complète, comme la principale — par exemple http://backup.example.com:8080",
  'Server address': "Adresse du serveur",
  'Add': "Ajouter",
  'Edit login': "Modifier la connexion",
  'Delete playlist': "Supprimer la liste",
  'This Playlist': "Cette liste",
  'Playlist enabled': "Liste activée",
  'Frees up this account\'s stream slot for another device — stops playback here immediately, keeps everything else intact.':
      "Libère la connexion de ce compte pour un autre appareil — arrête la lecture ici tout de suite et garde tout le reste.",
  'Login Details': "Infos de connexion",
  'Server': "Serveur",
  'Expires': "Expiration",
  'Max connections': "Connexions max.",
  'Backup Servers': "Serveurs de secours",
  'None yet. If your provider gave you more than one server address for this same account, add them here and this playlist will try them in order whenever the main one can\'t be reached.':
      "Aucun. Si votre fournisseur vous a donné plus d'une adresse de serveur pour ce compte, ajoutez-les ici : la liste les essaiera dans l'ordre quand la principale ne répond pas.",
  'Same username and password as above — only the address differs. Tried in order, a few seconds apart, and whichever answers is used first next time.':
      "Mêmes utilisateur et mot de passe que plus haut — seule l'adresse change. Les serveurs sont essayés dans l'ordre, à quelques secondes d'intervalle; celui qui répond passe en premier la fois suivante.",
  'Content Overview': "Aperçu du contenu",
  'Not loaded yet.': "Pas encore chargé.",
  '{p} live channels · {p2} movie categories · {p3} TV show categories':
      "{p} chaînes en direct · {p2} catégories de films · {p3} catégories de séries",
  '{p} live · {p2} movies · {p3} TV shows':
      "{p} en direct · {p2} films · {p3} séries",
  'Last updated: {p}': "Dernière MAJ : {p}",
  'Added: {p}': "Ajoutée : {p}",
  'Hidden Channels': "Chaînes masquées",
  'Hide a group here and it\'s excluded from the background download too, not just the browse tabs.':
      "Un groupe masqué ici est aussi exclu du téléchargement en arrière-plan, pas seulement des onglets.",
  'Full Catalog Sync': "Synchro complète du catalogue",
  'Update content every': "Intervalle de MAJ du contenu",
  '1 day': "1 jour",
  '{d} days': "{d} jours",
  'A stale sync prompts "Update content now?" on launch instead of running automatically.':
      "Une synchro trop vieille affiche « Mettre à jour le contenu? » au lancement au lieu de se faire automatiquement.",
  'in use': "utilisé",
  'Remove {server}': "Retirer {server}",
  'Which playlist\'s groups show first — set independently for each tab below.':
      "Quelle liste affiche ses groupes en premier — réglé séparément pour chaque onglet ci-dessous.",
  'Add another enabled playlist to set a priority between them.':
      "Ajoutez une autre liste activée pour choisir une priorité entre elles.",
  'Live TV order': "Ordre Télé en direct",
  'Movies order': "Ordre Films",
  'TV Shows order': "Ordre Séries",
  'Move up': "Monter",
  'Move down': "Descendre",
  'Playlist added': "Liste ajoutée",
  'This playlist is disabled on this device — enable it in Settings > Playlist Manager to watch.':
      "Cette liste est désactivée sur cet appareil — activez-la dans Paramètres > Gestion des listes pour regarder.",

  // ── Profiles / PIN ───────────────────────────────────────────────────
  'Profiles': "Profils",
  'Add Profile': "Ajouter un profil",
  'Rename profile': "Renommer le profil",
  'Delete "{name}"?': "Supprimer « {name} »?",
  'Their favorites, hidden groups, and watch history are deleted too. This can\'t be undone.':
      "Ses favoris, groupes masqués et historique sont aussi supprimés. C'est irréversible.",
  'Switch to another profile before deleting this one':
      "Passez à un autre profil avant de supprimer celui-ci",
  'Delete profile': "Supprimer le profil",
  'This is the active profile': "C'est le profil actif",
  'Switch to this profile': "Passer à ce profil",
  'Rename': "Renommer",
  'What this profile can see': "Ce que ce profil peut voir",
  'Groups — {name}': "Groupes — {name}",
  'Hidden channels — {name}': "Chaînes masquées — {name}",
  'For a child — hides every group, including adult content, by default. A parent unhides specific categories per playlist afterward in Group Management. A PIN is required to switch away from this profile or to open Settings while it\'s active.':
      "Pour un enfant — masque tous les groupes par défaut, y compris le contenu adulte. Un parent réaffiche ensuite des catégories précises par liste dans Gestion des groupes. Un NIP est requis pour quitter ce profil ou ouvrir les Paramètres quand il est actif.",
  'Create': "Créer",
  'Incorrect PIN': "NIP incorrect",
  "PINs didn't match — try again": "Les NIP ne correspondent pas — réessayez",
  'Enter PIN': "Entrez le NIP",
  'Confirm PIN': "Confirmez le NIP",
  'Set a PIN': "Choisissez un NIP",
  'Too many attempts — try again in {p}s':
      "Trop d'essais — réessayez dans {p} s",

  // ── Settings menu ────────────────────────────────────────────────────
  'M3U URL or Xtream Codes login': "URL M3U ou connexion Xtream Codes",
  'Every playlist: login, groups, enable/disable':
      "Toutes les listes : connexion, groupes, activer/désactiver",
  'Separate favorites, history & hidden groups per viewer':
      "Favoris, historique et groupes masqués distincts par personne",
  'Language and history': "Langue et historique",
  'Language, startup, Multiview and history':
      "Langue, démarrage, Multivue et historique",
  'Theme': "Thème",
  'Clock, accent color, layout': "Horloge, couleur, disposition",
  'Auto-refresh, channel matching & pairing, clear cache':
      "MAJ auto., association des chaînes, vider le cache",
  'TMDB (Release Dates)': "TMDB (dates de sortie)",
  'Optional key for sorting by real release date':
      "Clé facultative pour trier par vraie date de sortie",
  'Download and install the latest release':
      "Télécharger et installer la dernière version",
  'Version —': "Version —",
  'Version {version}': "Version {version}",
  'Report any bugs or glitches to noxqcx@gmail.com':
      "Signalez les bogues ou problèmes à noxqcx@gmail.com",

  // ── Theme ────────────────────────────────────────────────────────────
  'Show clock': "Afficher l'horloge",
  'Displays the current time in the top bar':
      "Affiche l'heure dans la barre du haut",
  'Theme color': "Couleur du thème",
  'Auto picks phone vs TV layout by screen size — force one if your box isn\'t detected correctly.':
      "« Auto » choisit la disposition téléphone ou télé selon l'écran — forcez-en une si votre boîtier est mal détecté.",
  'Live TV guide': "Guide télé en direct",
  'Timeline shows every channel at once, on a scrollable schedule grid, instead of one channel\'s now/next at a time.':
      "« Horaire » affiche toutes les chaînes en même temps dans une grille défilante, au lieu de l'en cours/ensuite d'une seule chaîne.",
  'Full-screen video behind the guide': "Vidéo plein écran derrière le guide",
  'The live channel fills the screen behind a see-through guide showing 3 rows':
      "La chaîne en direct remplit l'écran derrière un guide transparent de 3 rangées",
  'Auto': "Auto",
  'Phone': "Téléphone",
  'Timeline': "Horaire",
  'Platinum': "Platine",
  'Rosé': "Rosé",
  'Neon Purple': "Violet néon",
  'Neon Green': "Vert néon",
  'Aqua': "Aqua",
  'Red': "Rouge",
  'Blue': "Bleu",
  'Dark / Gold': "Noir / Or",

  // ── TMDB ─────────────────────────────────────────────────────────────
  'Cleared — TMDB sorting is now off': "Effacée — le tri TMDB est désactivé",
  'Saved — key verified with TMDB ✓': "Enregistrée — clé vérifiée avec TMDB ✓",
  'Saved, but TMDB rejected this key — double-check it\'s correct':
      "Enregistrée, mais TMDB a refusé cette clé — vérifiez-la",
  'What\'s New refreshed from TMDB': "Nouveautés actualisées depuis TMDB",
  'TMDB (The Movie Database) is a free, independent movie and TV database — not your IPTV provider. Adding your own free TMDB key lets VesperTV look up a title\'s actual real-world release date, which powers two things: a "TMDB" sort option on any group\'s "Expand catalog" screen, and a more accurate "What\'s New" row (ordered by real release date instead of just when your provider added the title).':
      "TMDB (The Movie Database) est une base de données gratuite et indépendante de films et séries — ce n'est pas votre fournisseur IPTV. Avec votre propre clé TMDB gratuite, VesperTV trouve la vraie date de sortie d'un titre, ce qui sert à deux choses : un tri « TMDB » dans l'écran « Catalogue complet » de chaque groupe, et une rangée « Nouveautés » plus juste (classée par vraie date de sortie plutôt que par date d'ajout chez votre fournisseur).",
  'This is completely optional and free — VesperTV works 100% without it. Without a key, sorting just falls back to whenever your provider added or updated each title, which is still available and works fine on its own.':
      "C'est entièrement facultatif et gratuit — VesperTV fonctionne à 100 % sans. Sans clé, le tri se fait selon la date d'ajout ou de MAJ chez votre fournisseur, ce qui fonctionne très bien aussi.",
  'To get one: create a free account at themoviedb.org, then generate an API key under Settings > API (choose "Personal use" when asked) and paste it below. VesperTV never collects or shares it — it\'s stored only on this device.':
      "Pour en avoir une : créez un compte gratuit sur themoviedb.org, puis générez une clé API dans Settings > API (choisissez « Personal use ») et collez-la ci-dessous. VesperTV ne la collecte ni ne la partage jamais — elle reste sur cet appareil.",
  'TMDB API Key': "Clé API TMDB",
  'What\'s New only re-checks TMDB about once a week on its own. Use this to force it right now instead of waiting — useful right after saving a key for the first time.':
      "Nouveautés ne revérifie TMDB qu'environ une fois par semaine. Utilisez ceci pour le forcer tout de suite — pratique juste après avoir enregistré une clé.",
  'Refresh What\'s New Now': "Actualiser les Nouveautés",
  'This product uses the TMDB API but is not endorsed or certified by TMDB.':
      "Ce produit utilise l'API TMDB, mais n'est ni approuvé ni certifié par TMDB.",

  // ── Loading phases / connection ──────────────────────────────────────
  'No Title': "Sans titre",
  'Reconnecting...': "Reconnexion…",
  'Trying to reconnect on backup servers ({p}/{candidates})...':
      "Reconnexion sur les serveurs de secours ({p}/{candidates})…",
  'Finding live channels... ({p} found)':
      "Recherche des chaînes en direct… ({p} trouvées)",
  'Finding movies... ({p} found)': "Recherche des films… ({p} trouvés)",
  'Finding TV shows... ({p} found)': "Recherche des séries… ({p} trouvées)",
  'Connecting to {label} ({p}/{candidates})...':
      "Connexion à {label} ({p}/{candidates})…",
  'Connected to {label}': "Connecté à {label}",
  'Connecting to {label} ({p}/{candidates})... failed':
      "Connexion à {label} ({p}/{candidates})… échec",
  'Finding live channels...': "Recherche des chaînes en direct…",
  'Finding live channels... ({loadedLive} found)':
      "Recherche des chaînes en direct… ({loadedLive} trouvées)",
  'Finding movie categories...': "Recherche des catégories de films…",
  'Finding movies... ({vodCategories} categories found)':
      "Recherche des films… ({vodCategories} catégories trouvées)",
  'Finding TV show categories...': "Recherche des catégories de séries…",
  'Finding TV shows... ({seriesCategories} categories found)':
      "Recherche des séries… ({seriesCategories} catégories trouvées)",
  'Loading full catalog in the background — {p}':
      "Chargement du catalogue en arrière-plan — {p}",
  'Ready': "Prêt",
  '{done}/{total} categories': "{done}/{total} catégories",

  'Failed to load EPG (HTTP {code})':
      "Échec du chargement du guide (HTTP {code})",
  'Failed to load playlist from {host} (HTTP {code})':
      "Échec du chargement de la liste depuis {host} (HTTP {code})",
  'Xtream request to {server} failed: {action} (HTTP {code})':
      "Échec de la requête Xtream à {server} : {action} (HTTP {code})",
  'Main': "Principal",
  '{h}h ': "{h} h ",

  // ── Small widgets ────────────────────────────────────────────────────
  'Unpin': "Retirer des favoris",
  'Pin as favorite': "Épingler aux favoris",
  'Next: {p}': "Ensuite : {p}",
  'NOW: {title} ({p}-{p2})': "EN COURS : {title} ({p}-{p2})",
  'NEXT: {title} ({p})': "ENSUITE : {title} ({p})",
  'Hold ': "Maintenir ",
  ' to resume': " pour reprendre",
  'Expand sidebar': "Agrandir le panneau",
  'Collapse sidebar': "Réduire le panneau",
  'Pinned channels': "Chaînes épinglées",
  'League manager': "Gestion des ligues",
  'Your leagues': "Vos ligues",
  'League bank': "Banque de ligues",
  'Every league is added.': "Toutes les ligues sont ajoutées.",
  'Added · hold to send back': "Ajoutée · maintenir pour la retirer",
  '{name} is back in the league bank':
      "{name} est de retour dans la banque de ligues",
  'England': "Angleterre",
  'Spain': "Espagne",
  'Germany': "Allemagne",
  'Italy': "Italie",
  'France': "France",
  'Europe': "Europe",
  'Cups': "Coupes",
  'Americas': "Amériques",
  'World': "Monde",
  'Women': "Féminin",
  'Basketball': "Basketball",
  'Hockey': "Hockey",
  'Baseball': "Baseball",
  'Other': "Autres",
  'Golf': "Golf",
  'Tennis': "Tennis",
  'Rugby': "Rugby",
  'Cricket': "Cricket",
  'Darts': "Fléchettes",
  'Fighting': "Combat",
  'Motorsport': "Sport automobile",
  'Always for {name}': "Toujours pour {name}",
  'Best for a channel that carries the whole series':
      "Idéal pour une chaîne qui diffuse toute la série",
  'Next game: {date}': "Prochain match : {date}",
  'No upcoming games listed yet for this league.':
      "Aucun match à venir pour cette ligue pour l'instant.",
  'Transfer to another device': "Transférer vers un autre appareil",
  'Copy all of your data to another device':
      "Copier toutes vos données sur un autre appareil",
  'Copies your playlists, favorites, hidden groups, profiles, watch progress, {tab} (leagues, favourite league, My Teams) and settings to another device. On the same Wi-Fi it goes straight across; anywhere else it goes through an encrypted upload only the code can open. Channels, movies and the guide download again on the new device.':
      "Copie vos listes, favoris, groupes masqués, profils, progression, {tab} (ligues, ligue favorite, Mes équipes) et réglages vers un autre appareil. Sur le même Wi-Fi, ça passe directement; ailleurs, ça passe par un envoi chiffré que seul le code peut ouvrir. Les chaînes, films et le guide se téléchargent de nouveau sur le nouvel appareil.",
  'This setup is too big to upload. Use the same-Wi-Fi transfer instead.':
      "Cette configuration est trop grosse pour l'envoi. Utilisez plutôt le transfert par le même Wi-Fi.",
  'Couldn\'t reach the VesperTV transfer server. Check this device\'s internet connection and try again.':
      "Impossible de joindre le serveur de transfert VesperTV. Vérifiez la connexion Internet de cet appareil et réessayez.",
  '{n} hour': "{n} heure",
  '{n} hours': "{n} heures",
  '{n} day': "{n} jour",
  '{n} days': "{n} jours",
  'Your setup is encrypted on this device and uploaded. Any device that enters the code can copy it until it expires — even with this device turned off. How long should it stay available?':
      "Votre configuration est chiffrée sur cet appareil puis envoyée. Tout appareil qui entre le code peut la copier jusqu'à son expiration — même si cet appareil est éteint. Combien de temps doit-elle rester disponible?",
  'Encrypting and uploading…': "Chiffrement et envoi…",
  'Works on any network until {time}':
      "Valide sur tout réseau jusqu'à : {time}",
  'Anyone with this code can copy your setup, playlist logins included. Changes made after this upload aren\'t in it — upload again to update it.':
      "Toute personne qui a ce code peut copier votre configuration, identifiants de listes compris. Les changements faits après cet envoi n'y sont pas — renvoyez-la pour la mettre à jour.",
  'Upload again': "Renvoyer",
  'Delete now': "Supprimer maintenant",
  'Nothing was found for that code. Check it — the upload may also have expired or been deleted.':
      "Rien n'a été trouvé pour ce code. Vérifiez-le — l'envoi a peut-être aussi expiré ou été supprimé.",
  '9 digits on the same Wi-Fi, 16 digits over the internet':
      "9 chiffres sur le même Wi-Fi, 16 chiffres par Internet",
  '24-hour clock': "Horloge 24 heures",
  'Times show as 21:30': "Les heures s'affichent ainsi : 21:30",
  'Times show as 9:30 PM': "Les heures s'affichent ainsi : 9:30 PM",
  'Welcome back, legend': "Bon retour, légende",
  'No favourites yet. Hold Select on a poster or a group to add one.':
      "Aucun favori pour l'instant. Maintiens OK sur une affiche ou un groupe pour en ajouter.",
  'Rotate': "Pivoter",
  'You have great taste': "Tu as vraiment bon goût",
  'Looking sharp today': "Tu as fière allure aujourd'hui",
  'You make this place better': "Tu rends cet endroit meilleur",
  'Hey superstar': "Salut, superstar",
  'You deserve this break': "Tu mérites cette pause",
  'You\'re doing amazing': "Tu fais un travail incroyable",
  'Hello, wonderful you': "Bonjour, toi la merveille",
  'Smart choice, as always': "Bon choix, comme toujours",
  'You light up the room': "Tu illumines la pièce",
  'Keep shining, you\'ve got this': "Continue de briller, tu gères",
  'You earned some fun today': "Tu as mérité un peu de plaisir aujourd'hui",
  'The world is better with you in it': "Le monde est meilleur avec toi",
  'Hey champ, welcome in': "Salut champion, entre donc",
  'Send from this device': "Envoyer depuis cet appareil",
  'Shows a code to enter on the other device':
      "Affiche un code à entrer sur l'autre appareil",
  'Both devices on the same Wi-Fi?': "Les deux appareils sur le même Wi-Fi?",
  'Send directly, without uploading': "Envoyer directement, sans téléversement",
  'Receive on this device': "Recevoir sur cet appareil",
  'Replaces this device\'s setup with the other one\'s':
      "Remplace la configuration de cet appareil par celle de l'autre",
  'This device isn\'t on a Wi-Fi or wired home network.':
      "Cet appareil n'est pas sur un réseau Wi-Fi ou filaire.",
  'Sent! Finish on the other device.': "Envoyé! Terminez sur l'autre appareil.",
  'This code has expired. Go back and start again.':
      "Ce code a expiré. Revenez en arrière et recommencez.",
  'On the other device, open Settings > Transfer to another device > Receive, and enter:':
      "Sur l'autre appareil, ouvrez Paramètres > Transférer vers un autre appareil > Recevoir, et entrez :",
  'This device: {address} · the code works once, for 10 minutes':
      "Cet appareil : {address} · le code sert une fois, pendant 10 minutes",
  'Couldn\'t find the other device. Check the code, and that both devices are on the same Wi-Fi with the code still showing.':
      "Impossible de trouver l'autre appareil. Vérifiez le code, et que les deux appareils sont sur le même Wi-Fi avec le code encore affiché.",
  'That code isn\'t right. Check it on the other device.':
      "Ce code n'est pas bon. Vérifiez-le sur l'autre appareil.",
  'That code has expired or was already used. Start again on the other device.':
      "Ce code a expiré ou a déjà servi. Recommencez sur l'autre appareil.",
  'The transfer didn\'t go through. Try again.':
      "Le transfert n'a pas fonctionné. Réessayez.",
  'Transfer complete': "Transfert terminé",
  'VesperTV will close now. Open it again to load your playlists.':
      "VesperTV va se fermer. Rouvrez-le pour charger vos listes.",
  'Enter the code shown on the other device':
      "Entrez le code affiché sur l'autre appareil",
  'Ready to copy': "Prêt à copier",
  '{playlists} playlists · {profiles} profiles · {favorites} favorites':
      "{playlists} listes · {profiles} profils · {favorites} favoris",
  'This replaces the playlists, favorites and settings on this device.':
      "Ceci remplace les listes, favoris et réglages de cet appareil.",
  'Replace my data': "Remplacer mes données",
  'Enter the address shown under the code on the other device (This device: …)':
      "Entrez l'adresse affichée sous le code sur l'autre appareil (Cet appareil : …)",
  'Code: {code}': "Code : {code}",
  'Type the address instead': "Entrer l'adresse à la place",
  '{n} playlist': "{n} liste",
  '{n} playlists': "{n} listes",
  '{n} profile': "{n} profil",
  '{n} profiles': "{n} profils",
  '{n} favorite': "{n} favori",
  '{n} favorites': "{n} favoris",
  'Clear favourites?': "Effacer les favoris?",
  "Removes every starred item and favourite group from this tab's Favourites.":
      "Retire tous les éléments étoilés et groupes favoris des Favoris de cet onglet.",
  'Favourites cleared.': "Favoris effacés.",
  'Delete watched history?': "Supprimer l'historique de visionnage?",
  'Removes the History list of live channels.':
      "Efface la liste Historique des chaînes en direct.",
  'Watched history deleted.': "Historique de visionnage supprimé.",
  'NFL RedZone channel': "Chaîne NFL RedZone",
  // Series detail screen
  'Resume {code}': "Reprendre {code}",
  'Play {code}': "Lire {code}",
  '{n} seasons': "{n} saisons",
  '{n} episodes': "{n} épisodes",
  '1 episode': "1 épisode",
  '{m} min': "{m} min",
  '{h} h {m} min': "{h} h {m}",
  'Episode {n}': "Épisode {n}",
  'Watched': "Vu",
  'More': "Plus",
  'Watching': "En lecture",
  'Marked as watched': "Marqué comme vu",
  'Marked as unwatched': "Marqué comme non vu",
  'Hold to mark as watched': "Maintenir pour marquer comme vu",
  'Hold to mark as unwatched': "Maintenir pour marquer comme non vu",
  'Cast: {names}': "Avec : {names}",
  'Director: {names}': "Réalisation : {names}",
  'Specials': "Épisodes spéciaux",
  'Movie and TV artwork and data may come from TMDB (The Movie Database).':
      "Les affiches et données des films et séries peuvent provenir de TMDB (The Movie Database).",
  '{appName} {version} is available': "{appName} {version} est disponible",
  "What's new:": "Nouveautés :",
  'A new version is ready to install.':
      "Une nouvelle version est prête à être installée.",
  'Skip this version': "Ignorer cette version",
  'Later': "Plus tard",
  'See all · stats': "Tout voir · stats",
  'Live games': "Matchs en direct",
  'Click a game for its stats': "Cliquez sur un match pour ses stats",
  'No games are live right now': "Aucun match en direct pour le moment",
  'RED ZONE': "ZONE ROUGE",
  'No channel': "Aucune chaîne",
  'Watch on {channel}': "Regarder sur {channel}",
  'No channel found. Hold OK on the game in {tab} to pick one.':
      "Aucune chaîne trouvée. Maintenez OK sur le match dans {tab} pour en choisir une.",
  '▲▼ scroll · Back closes': "▲▼ défiler · Retour ferme",
  'Passing': "Passes",
  'Rushing': "Course",
  'Receiving': "Réception",
  'Defense': "Défense",
  'Kicking': "Botté",
  'Forwards': "Attaquants",
  'Defensemen': "Défenseurs",
  'Goalies': "Gardiens",
  'Batting': "Au bâton",
  'Pitching': "Lanceurs",
  'Players': "Joueurs",
  'No stats for this game yet.': "Pas encore de stats pour ce match.",
  'Top performers': "Meilleurs joueurs",
  'Injuries': "Blessures",
  'Goals': "Buts",
  'pen.': "pén.",
  'Team stats': "Stats d'équipe",
  'OK = stats · hold OK = channels · ▶❚❚ = watch':
      "OK = stats · maintenir OK = chaînes · ▶❚❚ = regarder",
  '{channel} · full screen': "{channel} · plein écran",
  // ── Archive tab ──────────────────────────────────────────────────────
  "Add a source": "Ajouter une source",
  "Couldn't load the catalog: {error}":
      "Impossible de charger le catalogue : {error}",
  "Couldn't reach that link.": "Impossible de joindre ce lien.",
  "This link failed at the provider. Choose another stream.":
      "Ce lien a échoué chez le fournisseur. Choisissez un autre flux.",
  "Menu": "Menu",
  "No playable stream for this title.": "Aucun flux lisible pour ce titre.",
  "No sources yet.": "Aucune source pour l'instant.",
  "None of your sources has TV shows.": "Aucune de vos sources n'a de séries.",
  "None of your sources has movies.": "Aucune de vos sources n'a de films.",
  "Nothing here yet.": "Rien ici pour l'instant.",
  "Refresh": "Actualiser",
  "Source link (ends with manifest.json)":
      "Lien de la source (se termine par manifest.json)",
  "That source is already in the list.": "Cette source est déjà dans la liste.",
  "This source lists no episodes for this show.":
      "Cette source n'indique aucun épisode pour cette série.",
  "VesperTV ships no sources. The titles you open are requested from the source you added; nothing else is shared.":
      "VesperTV n'inclut aucune source. Les titres que vous ouvrez sont demandés à la source ajoutée; rien d'autre n'est partagé.",
  "Your sources": "Vos sources",
  "{n} TV show catalogs": "{n} catalogues de séries",
  "{n} movie catalogs": "{n} catalogues de films",
  "Check the link here, then press Add.":
      "Vérifiez le lien ici, puis appuyez sur Ajouter.",
  "Hide Movies": "Masquer Films",
  "Hide TV Shows": "Masquer Séries",
  "Hide Recordings": "Masquer les enregistrements",
  "Typing a key with a remote is painful. Scan this code with your phone camera and paste the key there — it appears here for you to check and save.":
      "Taper une clé avec une télécommande, c'est pénible. Scannez ce code avec l'appareil photo de votre téléphone et collez-y la clé — elle apparaît ici pour que vous la vérifiiez et l'enregistriez.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and save.":
      "Taper un long lien avec une télécommande, c'est pénible. Scannez ce code avec l'appareil photo de votre téléphone et collez-y le lien — il apparaît ici pour que vous le vérifiiez et l'enregistriez.",
  "Paste the key and tap Send to TV.":
      "Collez la clé et touchez Envoyer à la télé.",
  "Check it here, then press Save.":
      "Vérifiez-le ici, puis appuyez sur Enregistrer.",
  "Paste the link and tap Send to TV.":
      "Collez le lien et touchez Envoyer à la télé.",
  "Removes the Movies tab and movie search results.":
      "Retire l'onglet Films et les films des résultats de recherche.",
  "Removes the TV Shows tab and show search results.":
      "Retire l'onglet Séries et les séries des résultats de recherche.",
  "Removes the Recordings tab.": "Retire l’onglet Enregistrements.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and add.":
      "Taper un long lien avec une télécommande, c'est pénible. Scannez ce code avec l'appareil photo de votre téléphone et collez-y le lien — il apparaît ici pour que vous le vérifiiez et l'ajoutiez.",
  // Archive: rows, search, stream picker
  'Popular': 'Populaires',
  'New': 'Nouveautés',
  'Featured': 'En vedette',
  'Search movies': 'Rechercher des films',
  'Search TV shows': 'Rechercher des séries',
  'Title': 'Titre',
  'Searching…': 'Recherche…',
  'Clear search': 'Effacer la recherche',
  'Results for "{query}"': 'Résultats pour « {query} »',
  'No results for "{query}"': 'Aucun résultat pour « {query} »',
  'Choose a stream': 'Choisir un flux',
  'Stream {n}': 'Flux {n}',
  // Transfer: Archive tab data
  // Media Hub tab (was Extras, before that Archive) + Multiview toggle
  // Trakt & Simkl (trackers_screen.dart, tracker rows)
  'Watch tracking powered by Trakt and Simkl; VesperTV is not affiliated with or endorsed by either.':
      "Suivi de visionnage fourni par Trakt et Simkl; VesperTV n'est ni affilié à l'un ni approuvé par l'un ou l'autre.",
  'Powered by Trakt (trakt.tv) and Simkl (simkl.com).':
      "Fourni par Trakt (trakt.tv) et Simkl (simkl.com).",
  'VesperTV is not affiliated with or endorsed by Trakt or Simkl.':
      "VesperTV n'est ni affilié à Trakt ou Simkl, ni approuvé par eux.",
  'Trakt & Simkl': 'Trakt et Simkl',
  'Track what you watch, lists in the Media Hub':
      'Suivi de ce que vous regardez, listes dans le Media Hub',
  'Connected as {name} — press OK to disconnect':
      'Connecté en tant que {name} — OK pour déconnecter',
  'Not available in this build yet': 'Pas encore disponible dans cette version',
  'Connect a watch tracker: what you watch in the Media Hub is marked as watched on your account, and your lists show up as Media Hub rows. Nothing is sent unless you connect an account.':
      'Connectez un service de suivi : ce que vous regardez dans le Media Hub est marqué comme vu sur votre compte, et vos listes apparaissent en rangées dans le Media Hub. Rien n\'est envoyé si vous ne connectez pas de compte.',
  'Watchlist and trending rows, scrobbling':
      'Rangées watchlist et tendances, scrobbling',
  'Watching and plan-to-watch rows, scrobbling':
      'Rangées en cours et à voir, scrobbling',
  'Titles from your lists play through your stream add-ons (Media Hub sources), by IMDb id. Only titles with an IMDb id are reported.':
      'Les titres de vos listes sont lus par vos add-ons de flux (sources Media Hub), par identifiant IMDb. Seuls les titres avec un identifiant IMDb sont signalés.',
  '{name} connected.': '{name} connecté.',
  'Disconnect {name}?': 'Déconnecter {name}?',
  'Its rows leave the Media Hub and plays are no longer reported. Your account itself is untouched.':
      'Ses rangées quittent le Media Hub et les lectures ne sont plus signalées. Votre compte lui-même n\'est pas modifié.',
  'Disconnect': 'Déconnecter',
  'Couldn\'t reach {name}. Check the connection.':
      'Impossible de joindre {name}. Vérifiez la connexion.',
  'The code expired. Try again.': 'Le code a expiré. Réessayez.',
  'Sign-in was not completed. Try again.':
      'La connexion n\'a pas abouti. Réessayez.',
  'Connect {name}': 'Connecter {name}',
  'On your phone or computer, open':
      'Sur votre téléphone ou ordinateur, ouvrez',
  'and enter this code:': 'et entrez ce code :',
  'Waiting for you to approve…': 'En attente de votre approbation…',
  'Try again': 'Réessayer',
  'Trakt watchlist': 'Watchlist Trakt',
  'Trending on Trakt': 'Tendances sur Trakt',
  'Watching on Simkl': 'En cours sur Simkl',
  'Simkl plan to watch': 'À voir sur Simkl',
  // Multiview picker: Live now / Sports shortcuts
  '{n} channels': '{n} chaînes',
  'No live games on your channels right now':
      'Aucun match en direct sur vos chaînes pour le moment',
  // Media Hub: Connect Jellyfin / Emby (media_server_screen.dart)
  'Connect Jellyfin / Emby': 'Connecter Jellyfin / Emby',
  'User name': 'Nom d\'utilisateur',
  'Connect': 'Connecter',
  'Enter the server address and your user name.':
      'Entrez l\'adresse du serveur et votre nom d\'utilisateur.',
  'Wrong user name or password.':
      'Nom d\'utilisateur ou mot de passe incorrect.',
  'This account has no movie or TV library.':
      'Ce compte n\'a aucune bibliothèque de films ou de séries.',
  'Couldn\'t find a Jellyfin or Emby server at that address.':
      'Aucun serveur Jellyfin ou Emby trouvé à cette adresse.',
  'Sign in to your own Jellyfin or Emby server: its movie and TV libraries show up in the Media Hub. Files play as they are stored on the server (no transcoding).':
      'Connectez-vous à votre propre serveur Jellyfin ou Emby : ses bibliothèques de films et de séries apparaissent dans le Media Hub. Les fichiers sont lus tels qu\'ils sont stockés sur le serveur (sans transcodage).',
  'Your password is only sent to your server. VesperTV keeps the sign-in token the server gives back, not the password.':
      'Votre mot de passe n\'est envoyé qu\'à votre serveur. VesperTV garde le jeton de connexion que le serveur renvoie, pas le mot de passe.',
  'Media Hub': 'Media Hub',
  'Media Hub sources': 'Sources Media Hub',
  'Add-on sources for the Media Hub tab':
      'Sources d\'add-ons pour l\'onglet Media Hub',
  'Clear Media Hub?': 'Effacer le Media Hub?',
  'Clear Media Hub': 'Effacer le Media Hub',
  'Media Hub cleared.': 'Media Hub effacé.',
  'Include Media Hub tab data': 'Inclure les données de l\'onglet Media Hub',
  'Media Hub sources and their watch progress are sent too':
      'Les sources Media Hub et leur progression sont aussi envoyées',
  'The other device keeps its own Media Hub sources':
      'L\'autre appareil garde ses propres sources Media Hub',
  'Add a source to browse films and series. Any source that follows the catalog/stream add-on format works.':
      'Ajoutez une source pour parcourir des films et des séries. Toute source qui suit le format d\'add-on catalogue/flux fonctionne.',
  'That link isn\'t a Media Hub source (it needs movie or series streams).':
      'Ce lien n\'est pas une source Media Hub (il lui faut des flux de films ou de séries).',
  'Removes every Media Hub source and its saved catalog from this device.':
      'Retire toutes les sources Media Hub et leur catalogue enregistré de cet appareil.',
  'The Media Hub tab shows films and series from sources you add here. Any source that follows the catalog/stream add-on format works; a source that only offers streams by IMDb id gets its posters and episodes from Cinemeta. Only direct video links are played; torrent links are ignored.':
      'L\'onglet Media Hub montre des films et des séries des sources ajoutées ici. Toute source qui suit le format d\'add-on catalogue/flux fonctionne; une source qui n\'offre que des flux par identifiant IMDb prend ses affiches et ses épisodes chez Cinemeta. Seuls les liens vidéo directs sont lus; les liens torrent sont ignorés.',
  'Hide Media Hub': 'Masquer Media Hub',
  'Removes the Media Hub tab.': 'Retire l\'onglet Media Hub.',
  'Hide Multiview': 'Masquer Multivue',
  'Removes the Multiview row and the player\'s Open in Multiview button.':
      'Retire la ligne Multivue et le bouton Ouvrir en Multivue du lecteur.',
  // Extras genre filter
  'Genre': 'Genre',
  'All genres': 'Tous les genres',
  'genre.Action': 'Action',
  'genre.Adventure': 'Aventure',
  'genre.Animation': 'Animation',
  'genre.Biography': 'Biographie',
  'genre.Comedy': 'Comédie',
  'genre.Crime': 'Policier',
  'genre.Documentary': 'Documentaire',
  'genre.Drama': 'Drame',
  'genre.Family': 'Famille',
  'genre.Fantasy': 'Fantastique',
  'genre.History': 'Histoire',
  'genre.Horror': 'Horreur',
  'genre.Mystery': 'Mystère',
  'genre.Romance': 'Romance',
  'genre.Sci-Fi': 'Science-fiction',
  'genre.Sport': 'Sport',
  'genre.Thriller': 'Thriller',
  'genre.War': 'Guerre',
  'genre.Western': 'Western',
  'genre.Reality-TV': 'Téléréalité',
  'genre.Talk-Show': 'Talk-show',
  'genre.Game-Show': 'Jeu télévisé',
  // Sports: favourite league
  'OK: show/hide or add · Hold OK: favourite league, or send an added league back to the bank':
      'OK : afficher/masquer ou ajouter · Maintenir OK : ligue favorite, ou renvoyer une ligue ajoutée à la banque',
  'Make favourite league': 'En faire la ligue favorite',
  'Remove from favourite': 'Retirer des favoris',
  '{tab} opens on it and its games come first in Live now':
      '{tab} s\'ouvre dessus et ses matchs passent en premier dans En direct',
  'Send back to the league bank': 'Renvoyer à la banque de ligues',
  'Favourite league': 'Ligue favorite',
  // Player side panel: Pull stats
  '◀ ▶ tabs  ·  OK to watch  ·  Hold OK for stats  ·  Back to close':
      '◀ ▶ onglets  ·  OK pour regarder  ·  Maintenir OK : stats  ·  Retour pour fermer',
  // Sports hero on Windows
  'Click the game again or Enter: full screen  ·  Esc: stop':
      'Cliquez à nouveau sur le match ou Entrée : plein écran  ·  Échap : arrêter',
  'Click again: watch here  ·  Hold: pick the channel':
      'Cliquer à nouveau : regarder ici  ·  Maintenir : choisir la chaîne',
  // Extras floating Search / Genre bar
  'Movie genres': 'Genres de films',
  'TV show genres': 'Genres de séries',
  // Extras: watched history + recent searches
  'Recently watched': 'Regardés récemment',
  'Clear recent searches': 'Effacer les recherches récentes',
  // Data pool (player stream details, Settings > General)
  "Data pool": "Data pool",
  "Data pool display": "Affichage du Data pool",
  "Press OK while a live channel plays to open a second card under the channel info with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Appuyez sur OK pendant une chaîne en direct pour ouvrir une deuxième carte sous les infos de la chaîne, avec les détails du flux : résolution, images par seconde, codecs, débit, variantes de qualité, pistes audio, mémoire tampon et HDR. Désactivé : OK n'affiche que les infos de la chaîne.",
  "Reading the stream…": "Lecture du flux…",
  "Video": "Vidéo",
  "Video bitrate": "Débit vidéo",
  "Picture": "Image",
  "Quality variants": "Variantes de qualité",
  "One (not adaptive)": "Une seule (non adaptatif)",
  "Audio": "Audio",
  "Audio tracks": "Pistes audio",
  "Stream": "Flux",
  "Buffered": "En mémoire tampon",
  "{seconds} s": "{seconds} s",
  "State": "État",
  "Buffering…": "Mise en mémoire tampon…",
  "Playing for {time}": "Lecture depuis {time}",
  "Paused": "En pause",
  "Device HDR": "HDR de l'appareil",
  "Not reported by the stream": "Non indiqué par le flux",
  "Mono": "Mono",
  "Stereo": "Stéréo",
  "Direct stream": "Flux direct",
  "Yes": "Oui",
  "No": "Non",
  "Stream bitrate": "Débit du flux",
  "Declared bitrate": "Débit déclaré",
  "Dropped frames": "Images perdues",
  "(measured)": "(mesuré)",
  "Measuring…": "Mesure…",
  // Settings categories (left panel)
  "Playlists & guide": "Listes et guide",
  "Your playlists and their logins, the TV guide (EPG) and the viewer profiles.":
      "Vos listes et leurs identifiants, le guide TV (EPG) et les profils.",
  "Everything the Media Hub uses: its add-on sources, online subtitles, Trakt & Simkl watch tracking and the optional TMDB key.":
      "Tout ce que le Media Hub utilise : ses sources d’add-ons, les sous-titres en ligne, le suivi Trakt et Simkl et la clé TMDB facultative.",
  "Interface": "Interface",
  "How the app looks and what it shows: theme, tabs, matching the TV's frame rate, the player's extras and reminders.":
      "L’apparence et ce qui s’affiche : thème, onglets, fréquence d’images du téléviseur, extras du lecteur et rappels.",
  "Hide Movies, TV Shows, Media Hub, Recordings or Multiview":
      "Masquer Films, Séries, Media Hub, Enregistrements ou Multiview",
  "Fixes for the picture on some Fire TV sticks":
      "Correctifs pour l’image sur certaines clés Fire TV",
  "Dolby Atmos to your soundbar or receiver":
      "Dolby Atmos vers votre barre de son ou ampli",
  "Surround passthrough (Dolby Atmos)": "Son surround direct (Dolby Atmos)",
  "Sends Dolby Digital, Dolby Atmos and DTS sound to your soundbar or receiver untouched (HDMI passthrough), so it can play Atmos. Off: this device turns that sound into plain stereo/5.1 first, so Atmos is lost. While on, the volume of that sound is set on your TV or receiver only, and if you hear nothing on a channel, turn this off. Multiview always uses plain sound (passthrough there kept muted screens playing). Applies from the next channel.":
      "Envoie le son Dolby Digital, Dolby Atmos et DTS tel quel à votre barre de son ou ampli (passthrough HDMI), pour qu'il puisse jouer l'Atmos. Désactivé : cet appareil convertit d'abord ce son en stéréo/5.1 simple, et l'Atmos est perdu. Activé, le volume de ce son se règle uniquement sur votre téléviseur ou ampli, et si vous n'entendez rien sur une chaîne, désactivez-le. Le Multiview utilise toujours le son simple (le passthrough y laissait le son des écrans coupés). S'applique à partir de la chaîne suivante.",
  "Stream details when you press OK on a channel":
      "Détails du flux quand vous appuyez sur OK sur une chaîne",
  "One list for every playlist, or one per playlist":
      "Une liste pour toutes les listes, ou une par liste",
  "The connections tip when opening Multiview":
      "L’astuce sur les connexions à l’ouverture du Multiview",
  "The \"Hold > to resume\" pill": "La pastille « Maintenir > pour reprendre »",
  "Language and clock, what plays when the app starts, Fast startup, and clearing your history.":
      "Langue et horloge, ce qui joue au démarrage, Démarrage rapide, et l’effacement de l’historique.",
  "App language and 24-hour clock": "Langue de l’app et horloge 24 h",
  "Resume the last channel, Fast startup":
      "Reprendre la dernière chaîne, Démarrage rapide",
  "Clear searches, channels, Continue Watching":
      "Effacer recherches, chaînes, Reprendre la lecture",
  "Device & data": "Appareil et données",
  "Move your whole setup to another device, keep a backup of it, and update VesperTV.":
      "Copiez toute votre configuration sur un autre appareil, gardez-en une sauvegarde et mettez VesperTV à jour.",
  // Own live groups (Move to group)
  "Move to group…": "Déplacer vers un groupe…",
  "Move {name} to": "Déplacer {name} vers",
  "New group…": "Nouveau groupe…",
  "Back to {group}": "Retour dans {group}",
  "New group": "Nouveau groupe",
  "Group name": "Nom du groupe",
  "{name} is now in {group}": "{name} est maintenant dans {group}",
  "Delete this group": "Supprimer ce groupe",
  "{group} deleted. Its channels are back in their groups.":
      "{group} supprimé. Ses chaînes sont revenues dans leurs groupes.",
  // Fast startup
  "Fast startup": "Démarrage rapide",
  "Opens the app without waiting for Movies and TV Shows to load; they fill in a few seconds later. For fast devices — leave it off on an older box if the app closes by itself right after starting. Applies from the next start.":
      "Ouvre l’app sans attendre le chargement des Films et Séries ; ils se remplissent quelques secondes plus tard. Pour les appareils rapides — laissez-le désactivé sur un boîtier plus ancien si l’app se ferme toute seule juste après le démarrage. S’applique au prochain démarrage.",
  // Group hold menu: New group
  "{group} created. Hold OK on a channel > Move to group… to add channels.":
      "{group} créé. Maintenez OK sur une chaîne > Déplacer vers un groupe… pour y ajouter des chaînes.",
  // Channel menu: Remove from group
  "Remove from {group}": "Retirer de {group}",
  // Settings > Device & data > Send log
  "Send log": "Envoyer le journal",
  "Send the app's log to the developer":
      "Envoyer le journal de l'app au développeur",
  "Sending...": "Envoi...",
  "Send again": "Envoyer à nouveau",
  "Log sent. Your code:": "Journal envoyé. Votre code :",
  "Mention this code on Reddit or Discord with what happened, so the developer can find your log.":
      "Indiquez ce code sur Reddit ou Discord avec ce qui s'est passé, pour que le développeur trouve votre journal.",
  "Something not working? Send the app's log to the VesperTV developer. It holds what the app did recently (this session and the last one) and your device model, nothing else.":
      "Quelque chose ne marche pas ? Envoyez le journal de l'app au développeur de VesperTV. Il contient ce que l'app a fait récemment (cette session et la précédente) et le modèle de votre appareil, rien d'autre.",
  "Server addresses, user names, passwords and other private details are removed before sending.":
      "Les adresses de serveur, noms d'utilisateur, mots de passe et autres détails privés sont retirés avant l'envoi.",
  "Too many logs sent from here. Try again in an hour.":
      "Trop de journaux envoyés d'ici. Réessayez dans une heure.",
  "Couldn't send the log. Check the internet connection and try again.":
      "Impossible d'envoyer le journal. Vérifiez la connexion Internet et réessayez.",
  // Recordings (Sports Trak recording, Recordings tab)
  "Watch live": "Regarder en direct",
  "Play from the start": "Lire depuis le début",
  "What has been recorded so far": "Ce qui a été enregistré jusqu'ici",
  "Stop recording": "Arrêter l'enregistrement",
  "Keeps what has been recorded": "Garde ce qui a été enregistré",
  "Cancel recording": "Annuler l'enregistrement",
  "Delete recording": "Supprimer l'enregistrement",
  "Frees {size}": "Libère {size}",
  "Removes it from the list": "Le retire de la liste",
  "Recordings": "Enregistrements",
  "Recording every {team} game": "Enregistre chaque match de {team}",
  "Nothing recorded yet. Hold OK on a game in {tab} and pick Record, or hold OK on a live channel.":
      "Aucun enregistrement pour l'instant. Maintenez OK sur un match dans {tab} et choisissez Enregistrer, ou maintenez OK sur une chaîne en direct.",
  "Recording now": "En cours d'enregistrement",
  "Recorded": "Enregistrés",
  "{used} of {cap} GB used": "{used} utilisés sur {cap} Go",
  "REC · {size}": "ENR · {size}",
  "Waiting for a channel": "En attente d'une chaîne",
  "Interrupted · {size}": "Interrompu · {size}",
  "Missed": "Manqué",
  "Failed": "Échec",
  "Live channel": "Chaîne en direct",
  "Start early: {min} min": "Commencer en avance : {min} min",
  "Before the game's scheduled start": "Avant l'heure prévue du match",
  "Keep recording: {min} min": "Continuer : {min} min",
  "After the scheduled end, for overtime and delays":
      "Après la fin prévue, pour les prolongations et retards",
  "Space for recordings: {gb} GB": "Espace pour les enregistrements : {gb} Go",
  "{used} used. Recording stops when this is full or the storage has less than 1 GB left.":
      "{used} utilisés. L'enregistrement s'arrête quand cet espace est plein ou qu'il reste moins de 1 Go.",
  "Save recordings to": "Enregistrer dans",
  "USB drive / SD card": "Clé USB / carte SD",
  "This device": "Cet appareil",
  "{free} free of {total}": "{free} libres sur {total}",
  "Plug in a USB drive or SD card to record to it. Recordings on this device are deleted if VesperTV is uninstalled.":
      "Branchez une clé USB ou une carte SD pour y enregistrer. Les enregistrements sur cet appareil sont supprimés si VesperTV est désinstallé.",
  "Recording in progress": "Enregistrement en cours",
  "{title} is recording on {channel}. Your playlist allows one connection, so playing another of its channels stops the recording.":
      "{title} est en cours d'enregistrement sur {channel}. Votre playlist n'autorise qu'une connexion : lire une autre de ses chaînes arrête l'enregistrement.",
  "Recording cancelled": "Enregistrement annulé",
  "Not enough free space to record":
      "Pas assez d'espace libre pour enregistrer",
  "Recording {title}": "Enregistrement de {title}",
  "{title} will be recorded": "{title} sera enregistré",
  "No longer recording every {team} game":
      "Les matchs de {team} ne sont plus enregistrés",
  "Every {team} game will be recorded":
      "Chaque match de {team} sera enregistré",
  "Waiting for a channel in the guide": "En attente d'une chaîne dans le guide",
  "Record": "Enregistrer",
  "{channel} · starts now": "{channel} · commence maintenant",
  "{channel} · from {time}": "{channel} · à partir de {time}",
  "Stop recording every {team} game":
      "Ne plus enregistrer chaque match de {team}",
  "Record every {team} game": "Enregistrer chaque match de {team}",
  "Recordings already made are kept":
      "Les enregistrements déjà faits sont conservés",
  "One team at a time, on the channel {tab} picks":
      "Une équipe à la fois, sur la chaîne choisie par {tab}",
  "Replaces {team}": "Remplace {team}",
  "Recording stopped": "Enregistrement arrêté",
  "Margins, space and where recordings are saved":
      "Marges, espace et emplacement des enregistrements",
  "Record until the show ends": "Enregistrer jusqu'à la fin de l'émission",
  "Record until I stop it": "Enregistrer jusqu'à ce que je l'arrête",
  "Keeps going across shows (4 hours at most)":
      "Continue d'une émission à l'autre (4 heures au plus)",
  "{title} · stops at {time}": "{title} · s'arrête à {time}",
  "No guide for this channel: stops after 2 hours":
      "Pas de guide pour cette chaîne : s'arrête après 2 heures",
  // Media Hub: Ready tag / Debrid accounts
  "Cleared": "Effacé",
  "Saved — key verified ✓": "Enregistré — clé vérifiée ✓",
  "Saved, but {service} rejected the key — double-check it":
      "Enregistré, mais {service} a refusé la clé — vérifiez-la",
  "Debrid accounts": "Comptes debrid",
  "Optional keys for the \"Ready\" tag":
      "Clés optionnelles pour l'étiquette « Prêt »",
  "Some Media Hub sources answer Play with a short \"being downloaded\" video while they fetch a title into your debrid account. VesperTV then checks back every minute and puts a \"Ready\" tag on the title's poster once it's there.":
      "Certaines sources du Media Hub répondent à Lecture par une courte vidéo « en cours de téléchargement » pendant qu'elles récupèrent un titre dans votre compte debrid. VesperTV revérifie alors chaque minute et ajoute une étiquette « Prêt » sur l'affiche du titre dès qu'il est là.",
  "Optional: with your own key, your account confirms it directly. Without one, VesperTV asks the source again until the full file answers.":
      "Optionnel : avec votre propre clé, votre compte le confirme directement. Sans clé, VesperTV redemande à la source jusqu'à ce que le fichier complet réponde.",
  "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (API key). Kept in VesperTV and only used to read your downloads list.":
      "Real-Debrid : real-debrid.com/apitoken. TorBox : torbox.app/settings (clé API). Conservée dans VesperTV et utilisée seulement pour lire votre liste de téléchargements.",
  "Real-Debrid API token": "Jeton API Real-Debrid",
  "TorBox API key": "Clé API TorBox",
  // Sports Trak: League bank heading for college conferences
  "College": "Universitaire",
  // Settings > General > Support VesperTV
  "Support VesperTV": "Soutenir VesperTV",
  "Buy a coffee or become a Supporter": "Offrir un café ou devenir Supporter",
  "VesperTV is free and always will be: no ads, no tracking, no paid features. If you enjoy it, you can buy a coffee or become a Supporter to help pay for the server, the website and development.":
      "VesperTV est gratuit et le restera : pas de pub, pas de pistage, aucune fonction payante. Si vous l'aimez, vous pouvez offrir un café ou devenir Supporter pour aider à payer le serveur, le site et le développement.",
  "Supporting is a thank-you, never a paywall: everyone gets the same app.":
      "Soutenir est un merci, jamais un accès payant : tout le monde a la même application.",
  // Settings > General > Remote tips
  "Language and clock, what plays when the app starts, Fast startup, clearing your history, and remote tips.":
      "Langue et horloge, ce qui joue au démarrage, Démarrage rapide, l'effacement de l'historique et les astuces télécommande.",
  "Remote tips": "Astuces télécommande",
  "Every hold menu and shortcut, on your phone":
      "Chaque menu « maintenir » et raccourci, sur votre téléphone",
  "Every hold menu and remote shortcut, on one page: hold OK on channels, groups and posters, the side panel on ← in full screen, Multiview, Sports Trak and more.":
      "Chaque menu « maintenir » et raccourci de la télécommande sur une seule page : maintenir OK sur les chaînes, groupes et affiches, le panneau latéral avec ← en plein écran, Multiview, Sports Trak et plus.",
  "Scan with your phone, or open": "Scannez avec votre téléphone, ou ouvrez",
  "Open": "Ouvrir",
  "The basics: hold OK (about half a second) opens a menu almost everywhere. Back always steps out one level. OK twice on a channel = full screen.":
      "L'essentiel : maintenir OK (environ une demi-seconde) ouvre un menu presque partout. Retour recule toujours d'un niveau. OK deux fois sur une chaîne = plein écran.",
  "Fetching…": "Récupération…",
  // Media Hub: list-only sources
  "Plays through your other sources": "Joue via vos autres sources",
  // Search: Media Hub results
  "Search Live TV, Movies, TV Shows & the Media Hub":
      "Rechercher la télé en direct, les films, les séries et le Media Hub",
  // Player: what an unreadable link really served
  "This file's format can't be played here. Try another stream (an MKV or MP4 one).":
      "Le format de ce fichier ne peut pas être lu ici. Essayez un autre flux (MKV ou MP4).",
  "Your source sent a message instead of the video:":
      "Votre source a envoyé un message au lieu de la vidéo :",
  "Check your source or debrid account (plan limits, active downloads), or pick another stream.":
      "Vérifiez votre source ou votre compte debrid (limites du forfait, téléchargements actifs), ou choisissez un autre flux.",
  // Media Hub: import add-ons (pasted links, Stremio)
  "Added to the Media Hub: {names}": "Ajouté au Media Hub : {names}",
  "Added to subtitle add-ons: {names}":
      "Ajouté aux add-ons de sous-titres : {names}",
  "Already added: {names}": "Déjà ajouté : {names}",
  "Not usable in VesperTV: {names}": "Inutilisable dans VesperTV : {names}",
  "Couldn't reach: {names}": "Inaccessible : {names}",
  "Import from Stremio": "Importer depuis Stremio",
  "Couldn't reach Stremio. Check your internet connection.":
      "Impossible de joindre Stremio. Vérifiez votre connexion Internet.",
  "Couldn't read your Stremio add-ons. Try again.":
      "Impossible de lire vos add-ons Stremio. Réessayez.",
  "Copy the add-ons from your Stremio account. Nothing is changed on your Stremio account.":
      "Copiez les add-ons de votre compte Stremio. Rien n'est modifié sur votre compte Stremio.",
  "On your phone, scan the code or open":
      "Sur votre téléphone, scannez le code ou ouvrez",
  "Code": "Code",
  "Then sign in to Stremio there. This page continues on its own.":
      "Puis connectez-vous à Stremio. Cette page continue toute seule.",
  "Your Stremio account has no add-ons VesperTV can copy.":
      "Votre compte Stremio n'a aucun add-on que VesperTV peut copier.",
  "Your Stremio add-ons. Untick any you don't want.":
      "Vos add-ons Stremio. Décochez ceux que vous ne voulez pas.",
  "Add {n} add-ons": "Ajouter {n} add-ons",
  "Already added": "Déjà ajouté",
  "Can't play in VesperTV": "Impossible à lire dans VesperTV",
  "Several links at once work too.":
      "Plusieurs liens à la fois, ça marche aussi.",
  "{n} links checked": "{n} liens vérifiés",
  // Data pool on movies / episodes
  "Press OK while a channel, movie or episode plays to open a card with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Appuyez sur OK pendant la lecture d'une chaîne, d'un film ou d'un épisode pour ouvrir une carte avec les détails du flux : résolution, images par seconde, codecs, débit, variantes de qualité, pistes audio, mémoire tampon et HDR. Désactivé : OK affiche seulement les infos de la chaîne.",
  "Stream details when you press OK while watching":
      "Détails du flux quand vous appuyez sur OK en regardant",
  // CFL official feed
  'East Division': 'Division Est',
  'West Division': 'Division Ouest',
  'Score unavailable': 'Score indisponible',
  'Passing yards': 'Verges par la passe',
  'Rushing yards': 'Verges au sol',
  'Net offence': 'Attaque nette',
  'First downs': 'Premiers essais',
  'Sacks': 'Sacs du quart',
  '2nd down conversions': 'Conversions au 2e essai',
  'Turnovers': 'Revirements',
  'Penalties (yards)': 'Pénalités (verges)',
  'Field goals': 'Bottés de placement',
  'Time of possession': 'Temps de possession',
  'Punting': 'Dégagements',
  'Kickoffs': 'Bottés d’envoi',
  'Kickoff returns': 'Retours de botté d’envoi',
  'Punt returns': 'Retours de dégagement',

  "Pick channels myself": "Choisir mes chaînes",
  "All groups": "Tous les groupes",
  "{count} selected": "{count} sélectionnées",
  "Select results": "Sélectionner les résultats",
  "Clear results": "Désélectionner les résultats",
  "Browse all channels": "Voir toutes les chaînes",
  "My sports channels": "Mes chaînes de sport",
  "List name": "Nom de la liste",
  "Add to list": "Ajouter à la liste",
  "Create list": "Créer une liste",
  "Edit list": "Modifier la liste",
  "Versions": "Versions",
  "My lists": "Mes listes",
  "League networks": "Chaînes de ligues",
  "Sports networks": "Chaînes de sport",
  "Regional channels": "Chaînes régionales",
  "Channels": "Chaînes",
  "Games": "Matchs",
  "Use a playlist group": "Utiliser un groupe de liste",
  "Rename list": "Renommer la liste",
  "Delete list": "Supprimer la liste",

  "Filters": "Filtres",
  "Edit tags": "Modifier les étiquettes",
  "Country": "Pays",
  "Network": "Réseau",
  "Sport": "Sport",
  "League": "Ligue",
  "Group": "Groupe",
  "Unknown": "Inconnu",
  "Clear all": "Tout effacer",
  "Keep this list updated": "Garder cette liste à jour",
  "Comma-separated tags": "Étiquettes séparées par des virgules",
  "Add sources": "Ajouter des sources",
  "More sources": "Plus de sources",
  "Your added source": "Votre source ajoutée",
  "This game": "Ce match",
  "hockey": "Hockey",
  "basketball": "Basketball",
  "football": "Football américain",
  "soccer": "Football",
  "baseball": "Baseball",
  "tennis": "Tennis",
  "golf": "Golf",
  "racing": "Course automobile",

  "Trailer": "Bande-annonce",
  "Cast": "Distribution",
  "Unable to open trailer": "Impossible d’ouvrir la bande-annonce",
  "Next episode airs {date}": "Le prochain épisode sera diffusé le {date}",
  "Next episode: {code} · {date}": "Prochain épisode : {code} · {date}",
  "YouTube playback needs Android System WebView or Microsoft Edge WebView2.":
      "La lecture YouTube nécessite Android System WebView ou Microsoft Edge WebView2.",
  "YouTube could not play this video ({code}).":
      "YouTube ne peut pas lire cette vidéo ({code}).",
  "Open in YouTube": "Ouvrir dans YouTube",
  "Back 10 seconds": "Reculer de 10 secondes",
  "Forward 10 seconds": "Avancer de 10 secondes",
  "Play / pause": "Lecture / pause",
  "Mark season watched": "Marquer la saison comme vue",
  "Mark season unwatched": "Marquer la saison comme non vue",
  "Season {season} marked as watched": "Saison {season} marquée comme vue",
  "Season {season} marked as unwatched":
      "Saison {season} marquée comme non vue",
  "Colour": "Couleur",
  "Kids profile": "Profil enfant",
  "Photo": "Photo",
  "Profile": "Profil",
  "Actions": "Actions",
  "Active": "Actif",
  "Kids & PIN": "Enfants et code PIN",
  "Scan with your phone to add a photo":
      "Scannez avec votre téléphone pour ajouter une photo",
  "Choose a photo": "Choisir une photo",
  "Remove photo": "Supprimer la photo",
  "Choose a photo and tap Send to TV.":
      "Choisissez une photo et appuyez sur Envoyer à la TV.",
  "Your photo appears here automatically.":
      "Votre photo apparaît ici automatiquement.",
  "Could not read photo. Choose a JPEG or PNG under 2 MB.":
      "Photo illisible. Choisissez un JPEG ou PNG de moins de 2 Mo.",
  "Could not save profile. Try again.":
      "Impossible de sauvegarder le profil. Réessayez.",
  "Watch history": "Historique de visionnage",
  "Hidden groups and channels": "Groupes et chaînes masqués",
  "Home rows layout": "Disposition des rangées d’accueil",
  "What should this profile get from Main?":
      "Que doit recevoir ce profil de Principal ?",
  "Copies are independent. Playlists, accounts and device settings stay shared.":
      "Les copies sont indépendantes. Listes, comptes et réglages de l’appareil restent partagés.",
  "Everything": "Tout",
  "None": "Rien",
  "Save name": "Enregistrer le nom",
  "Saving…": "Enregistrement…",
  "Profile restrictions are fixed when the profile is created.":
      "Les restrictions sont fixées à la création du profil.",
  "{n} groups allowed": "{n} groupes autorisés",
  "{groups} groups hidden · {channels} channels hidden":
      "{groups} groupes masqués · {channels} chaînes masquées",
  "Main cannot be deleted": "Le profil Principal ne peut pas être supprimé",
  "Hold OK on a profile to edit it. Hold OK on a season to mark it watched or unwatched.":
      "Maintenez OK sur un profil pour le modifier, ou sur une saison pour la marquer vue ou non vue.",
  'Coming soon': 'Bientôt disponible',
  "Show Cinemeta catalog": "Afficher le catalogue Cinemeta",
  "Show the default Popular, New and Featured rows and Cinemeta search results. Turn off to browse only your own catalogs. Posters and episode details may still use Cinemeta.":
      "Afficher les lignes par défaut Populaires, Nouveautés et À la une et les résultats de recherche Cinemeta. Désactivez pour parcourir uniquement vos propres catalogues. Les affiches et les détails des épisodes peuvent toujours provenir de Cinemeta.",
  "Expand": "Agrandir",
  "Fill the screen with the Timeline guide":
      "Afficher le guide horaire sur tout l’écran",
  "The live channel fills the screen behind a see-through guide":
      "La chaîne en direct remplit l’écran derrière un guide transparent",
  "Source: {source}": "Source : {source}",
  "File size: {size}": "Taille du fichier : {size}",
  "File size unavailable": "Taille du fichier indisponible",

  // Automatic detail trailers.
  "Automatic trailers": "Bandes-annonces automatiques",
  "Play available trailers automatically with sound on IPTV and Media Hub movie and show pages.":
      "Lire automatiquement avec le son les bandes-annonces disponibles sur les pages des films et séries IPTV et Media Hub.",
  "Trailers": "Bandes-annonces",
  "Play trailers automatically on movie and show pages":
      "Lecture automatique des bandes-annonces sur les pages de films et séries",
  "On Fire TV sticks, the trailer plays full screen.":
      "Sur les Fire TV Stick, la bande-annonce s'affiche en plein écran.",
  "Remove \"{title}\" from history?": "Retirer « {title} » de l’historique ?",
  "Import from storage": "Importer depuis un stockage",
  "Add M3U playlists and Media Hub sources from USB or external storage":
      "Ajouter des listes M3U et sources Media Hub depuis USB ou un stockage externe",
  "Choose a folder": "Choisir un dossier",
  "Import from storage?": "Importer depuis ce stockage ?",
  "Import": "Importer",
  "Import \"{name}\"? M3U playlists and included Media Hub sources are added without replacing your current setup.":
      "Importer « {name} » ? Les listes M3U et les sources Media Hub incluses sont ajoutées sans remplacer votre configuration.",
  "Import M3U playlists and Media Hub source links from USB, SD card or external storage. Choose M3U/M3U8 playlists or TXT/JSON source files.":
      "Importez des listes M3U et liens de sources Media Hub depuis USB, carte SD ou stockage externe. Choisissez des listes M3U/M3U8 ou des fichiers de sources TXT/JSON.",
  "Could not read this storage location. Use Choose a folder to grant access.":
      "Impossible de lire ce stockage. Utilisez Choisir un dossier pour autoriser l’accès.",
  "No folder picker on this device. Browse the storage devices below instead.":
      "Aucun sélecteur de dossier sur cet appareil. Parcourez les stockages ci-dessous.",
  "No playlists or source files in this folder.":
      "Aucune liste ni fichier de sources dans ce dossier.",
  "Imported {items} playlist items and {sources} Media Hub sources. {existing} sources already existed; {failed} could not be reached.":
      "{items} éléments de liste et {sources} sources Media Hub importés. {existing} sources existaient déjà ; {failed} étaient injoignables.",
  "Could not import this file. Choose an M3U channel playlist or a TXT/JSON file containing Media Hub manifest links.":
      "Importation impossible. Choisissez une liste de chaînes M3U ou un fichier TXT/JSON contenant des liens de manifestes Media Hub.",
  "Hide profiles": "Masquer les profils",
  "Hides the profiles row on Home.":
      "Masque la rangée des profils sur l’accueil.",
  "Preferred audio language": "Langue audio préférée",
  "Preferred subtitle language": "Langue de sous-titres préférée",
  "Source default": "Par défaut de la source",
  "Movies and episodes use these languages when available. Your manual track choices take priority when resuming.":
      "Les films et épisodes utilisent ces langues si elles sont disponibles. Vos choix manuels de pistes sont prioritaires à la reprise.",
  "Playback": "Lecture",
  "Frame rate & resolution": "Fréquence d’images et résolution",
  "Video, audio, subtitles, trailers and player behaviour.":
      "Vidéo, audio, sous-titres, bandes-annonces et comportement du lecteur.",
  "Theme, tabs, favourites and how the app looks.":
      "Thème, onglets, favoris et apparence de l’application.",
  "Audio languages, subtitles and surround sound":
      "Langues audio, sous-titres et son ambiophonique",
  "Media Hub playback": "Lecture du Media Hub",
  "Default stream selection for movies and episodes":
      "Sélection du flux par défaut pour les films et épisodes",
  "Boxing": "Boxe",
  "Stream sources": "Sources du flux",
  "Up/Down: browse · OK: switch · Back: close":
      "Haut/Bas : parcourir · OK : changer · Retour : fermer",
  "Could not load stream sources.":
      "Impossible de charger les sources du flux.",
  "Could not switch stream. Try another source.":
      "Impossible de changer de flux. Essayez une autre source.",
  "Current stream": "Flux actuel",
  "Size unknown": "Taille inconnue",
  "View source URL": "Voir l’URL de la source",
  "Source URL": "URL de la source",
  "Copy URL": "Copier l’URL",
  "URL copied": "URL copiée",
  "Goals alert": "Alerte de buts",
  "Score alerts for My Teams on any screen":
      "Alertes de score de Mes équipes sur tous les écrans",
  "Show a top-left popup when a team in My Teams scores. Alerts follow the score feed and pause when scores are hidden.":
      "Afficher une notification en haut à gauche lorsqu’une équipe de Mes équipes marque. Les alertes suivent les mises à jour du score et s’arrêtent quand les scores sont masqués.",
  "{team} scored!": "{team} a marqué !",
  "{first} {firstScore} – {secondScore} {second}":
      "{first} {firstScore} – {secondScore} {second}",
  'Catch-up is not available for this channel.':
      'Le rattrapage n’est pas disponible pour cette chaîne.',
  'This programme is not available in catch-up.':
      'Cette émission n’est pas disponible en rattrapage.',
  "Hide Catch-up group": "Masquer le groupe Rattrapage",
  "Removes the TV tab's Catch-up row (every channel you can replay).":
      "Retire la ligne Rattrapage de l'onglet TV (toutes les chaînes à revoir).",
  "No channels with catch-up.": "Aucune chaîne avec rattrapage.",
  "Catch-up playlists": "Playlists du rattrapage",
  "Hidden here · {n} channels": "Masquée ici · {n} chaînes",
  'Catch-up': 'Rattrapage',
  'Previous programme': 'Émission précédente',
  'Next programme': 'Émission suivante',
  'Watch from the start': 'Regarder depuis le début',
  '{time} behind live': '{time} de retard sur le direct',
  'Back to live': 'Retour au direct',
  'Catch-up {time}': 'Rattrapage {time}',
  'Now': 'Maintenant',
  "Refined finish": "Finition raffinée",
  "Glossy surfaces, reflections and blur. Uses more graphics resources.":
      "Surfaces brillantes, reflets et flou. Utilise davantage de ressources graphiques.",
  "Video HDR": "HDR vidéo",
  "Decoder HDR": "HDR décodé",
  "Unknown / not reported": "Inconnu / non indiqué",
  "{format} (stream)": "{format} (flux)",
  "{format} (decoder)": "{format} (décodeur)",
  "File size": "Taille du fichier",

  // Match-specific score alerts.
  "Remove goals alert for {league}":
      "Désactiver les alertes de buts pour {league}",
  "Goals alert for all of {league}": "Alertes de buts pour toute la {league}",
  "Notify me of every goal in this league (while VesperTV is open). Hide scores pauses alerts.":
      "M'avertir de chaque but de cette ligue (quand VesperTV est ouvert). Masquer les scores met les alertes en pause.",
  "Watch game button": "Bouton Regarder le match",
  "A reminded game offers Watch game in the player at kickoff":
      "Un match avec rappel propose Regarder le match dans le lecteur au coup d'envoi",
  "When a reminded game is about to start, a Watch game button shows in the player for 10 minutes. Press Up from the player bar to reach it, then OK to switch to the game on its best channel. Set a reminder with a hold on the game. {app} must be open. Saved for this viewer.":
      "Quand un match avec rappel va commencer, un bouton Regarder le match s'affiche dans le lecteur pendant 10 minutes. Appuyez sur Haut depuis la barre du lecteur pour l'atteindre, puis OK pour passer au match sur sa meilleure chaîne. Ajoutez un rappel en maintenant OK sur le match. {app} doit être ouvert. Enregistré pour ce profil.",
  "Watch game": "Regarder le match",
  "When the next episode starts by itself":
      "Quand l'épisode suivant démarre tout seul",
  "Play the next episode": "Lancer l'épisode suivant",
  "30 seconds before the end": "30 secondes avant la fin",
  "When the episode ends": "À la fin de l'épisode",
  "Never": "Jamais",
  "{when}. On TV show episodes, the Up Next card counts down and the next episode starts by itself. Never: no countdown; the episode plays to its end.":
      "{when}. Sur les épisodes de séries, la carte À suivre fait un compte à rebours puis l'épisode suivant démarre tout seul. Jamais : pas de compte à rebours, l'épisode joue jusqu'à la fin.",
  "Set goals alert for this match": "Activer les alertes de buts pour ce match",
  "Remove goals alert for this match":
      "Supprimer les alertes de buts pour ce match",
  "Notify me when either team scores (while VesperTV is open). Hide scores pauses alerts.":
      "Me prévenir quand une des deux équipes marque (pendant que VesperTV est ouvert). Masquer les scores suspend les alertes.",
  "Could not save score alert.": "Impossible d’enregistrer l’alerte de score.",
  // Game reminder timing.
  "1 hour before": "1 heure avant",
  "1 day before": "1 jour avant",
  "1 week before": "1 semaine avant",
  "At game time only": "Uniquement au début du match",
  "15 minutes before": "15 minutes avant",
  "Reminder timing": "Horaire du rappel",
  "Advance reminders also notify at game time. VesperTV must be open.":
      "Les rappels anticipés préviennent aussi au début du match. VesperTV doit être ouvert.",
  "This reminder time has passed": "L’heure de ce rappel est déjà passée",
  "Choose when to be reminded (while VesperTV is open)":
      "Choisissez quand recevoir le rappel (pendant que VesperTV est ouvert)",
  "Starts in 1 hour": "Commence dans 1 heure",
  "Starts in 1 day": "Commence dans 1 jour",
  "Starts in 1 week": "Commence dans 1 semaine",
  "Schedule": "Calendrier",
  "Every game of the season, cups included":
      "Tous les matchs de la saison, coupes comprises",
  "Could not load the schedule.": "Impossible de charger le calendrier.",
  "OK: stats, watch or game menu · Hold OK: game menu · CH+/CH-: month":
      "OK : stats, regarder ou menu du match · Maintenir OK : menu du match · CH+/CH- : mois",
  "No game this day.": "Aucun match ce jour-là.",
  "Next game": "Prochain match",
  "Newest": "Nouveautés",
  'What happens when a catch-up programme ends':
      "Ce qui se passe à la fin d'un programme en rattrapage",
  'Keep playing after the programme': "Continuer après le programme",
  "Off: catch-up pauses when the programme you picked ends, so the next one doesn't start on its own; press Play to carry on. On: it keeps going like the channel did.":
      "Désactivé : le rattrapage se met en pause à la fin du programme choisi, le suivant ne démarre pas tout seul ; appuyez sur Lecture pour continuer. Activé : la lecture continue comme sur la chaîne.",
  "Channel schedule": "Programme de la chaîne",
  "▲ ▼ programmes  ·  OK to watch  ·  Back to close":
      "▲ ▼ émissions  ·  OK pour regarder  ·  Retour pour fermer",
  "On now  ·  OK to watch live": "En cours  ·  OK pour regarder en direct",
  "Catch-up  ·  OK to watch from the start":
      "Rattrapage  ·  OK pour regarder depuis le début",
  "Upcoming": "À venir",
  "Show group counts": "Afficher le nombre par groupe",
  "How many channels, movies or shows each group holds, beside its name.":
      "Le nombre de chaînes, films ou séries de chaque groupe, à côté de son nom.",
  "{m} min back": "{m} min en arrière",

  // Upcoming TV programmes
  "Starts in 5 minutes": "Commence dans 5 minutes",
  "5 minutes before and at programme time (while VesperTV is open)":
      "5 minutes avant et au début de l’émission (lorsque VesperTV est ouvert)",
  "Overlaps {title}. Your playlist has no free recording connection.":
      "Chevauche {title}. Votre playlist n’a plus de connexion libre pour enregistrer.",
  "Records the programme start to end. Manage it in Recordings.":
      "Enregistre l’émission du début à la fin. Gérez-la dans Enregistrements.",
  "Could not schedule recording. Check recording storage and try again.":
      "Impossible de programmer l’enregistrement. Vérifiez le stockage et réessayez.",
  "▲ ▼ programmes  ·  OK for options  ·  Back to close":
      "▲ ▼ émissions  ·  OK pour les options  ·  Retour pour fermer",
  "Upcoming  ·  OK to remind or record":
      "À venir  ·  OK pour un rappel ou un enregistrement",
  "Recording scheduled. Android may delay the start without exact alarm access.":
      "Enregistrement programmé. Android peut retarder le début sans autorisation d’alarme exacte.",

  // Plex media-server connector.
  "Connect Jellyfin / Emby / Plex": "Connecter Jellyfin / Emby / Plex",
  "Connect Plex": "Connecter Plex",
  "Sign in on your phone and choose a Plex server":
      "Connectez-vous sur votre téléphone et choisissez un serveur Plex",
  "Sign in with Plex on your phone, then choose a server. Your movie and TV libraries appear in the Media Hub. Files play directly, without transcoding.":
      "Connectez-vous à Plex sur votre téléphone, puis choisissez un serveur. Vos bibliothèques de films et séries apparaissent dans le Media Hub. Les fichiers sont lus directement, sans transcodage.",
  "Could not connect to Plex. Try again.":
      "Connexion à Plex impossible. Réessayez.",
  "Plex sign-in expired. Try again.": "La connexion Plex a expiré. Réessayez.",
  "Plex access was denied. Sign in again.":
      "Accès à Plex refusé. Reconnectez-vous.",
  "Could not reach this Plex server. Check that it is online and accessible from this device.":
      "Serveur Plex inaccessible. Vérifiez qu’il est en ligne et accessible depuis cet appareil.",
  "Choose a Plex server": "Choisissez un serveur Plex",
  "No Plex servers are available on this account.":
      "Aucun serveur Plex disponible sur ce compte.",
  "Sign in again": "Se reconnecter",
  "Scan the QR code or visit {url} and enter this code:":
      "Scannez le code QR ou visitez {url} et saisissez ce code :",

  // Title page row order.
  "Customize title page": "Personnaliser la fiche",
  "Choose the order of rows below title details. Saved for this viewer.":
      "Choisissez l’ordre des rangées sous les détails du titre. Enregistré pour ce profil.",

  // My Teams preferred channel.
  "Set preferred channel": "Choisir la chaîne préférée",
  "Automatic channel": "Chaîne automatique",
  "Preferred channel for {team}": "Chaîne préférée pour {team}",
  "Saved channel is unavailable": "La chaîne enregistrée est indisponible",
  "Hold OK on a team for schedule, preferred channel or unfollow · on a game to pick the channel":
      "Maintenir OK sur une équipe : calendrier, chaîne préférée ou ne plus suivre · sur un match : choisir la chaîne",

  // Sports channel country preferences.
  "Channel preferences and settings for {tab}.":
      "Préférences de chaînes et réglages de {tab}.",
  "Preferred channel countries": "Pays préférés pour les chaînes",
  "Prefer local channels while keeping other matches available":
      "Privilégier les chaînes locales tout en gardant les autres correspondances",
  "Prefer these countries among channels that match the game. Other countries remain available. Your game and team channel choices still come first.":
      "Privilégiez ces pays parmi les chaînes correspondant au match. Les autres pays restent disponibles. Vos choix de chaîne pour un match ou une équipe restent prioritaires.",
  "Selected countries have equal priority. Match evidence comes before country, then video quality within each group. Saved for this viewer.":
      "Les pays sélectionnés ont la même priorité. Les indices du match passent avant le pays, puis la qualité vidéo dans chaque groupe. Enregistré pour ce profil.",
  "No country preference": "Aucune préférence de pays",
  "Keep the current automatic ranking":
      "Conserver le classement automatique actuel",
  "Canada": "Canada",
  "United States": "États-Unis",
  "United Kingdom": "Royaume-Uni",
  "Portugal": "Portugal",
  "Greece": "Grèce",
  "Ireland": "Irlande",
  "Netherlands": "Pays-Bas",
  "Belgium": "Belgique",
  "Switzerland": "Suisse",
  "Austria": "Autriche",
  "Denmark": "Danemark",
  "Sweden": "Suède",
  "Norway": "Norvège",
  "Finland": "Finlande",
  "Poland": "Pologne",
  "Czechia": "Tchéquie",
  "Slovakia": "Slovaquie",
  "Hungary": "Hongrie",
  "Romania": "Roumanie",
  "Bulgaria": "Bulgarie",
  "Croatia": "Croatie",
  "Serbia": "Serbie",
  "Slovenia": "Slovénie",
  "Bosnia and Herzegovina": "Bosnie-Herzégovine",
  "Albania": "Albanie",
  "Türkiye": "Turquie",
  "Ukraine": "Ukraine",
  "Australia": "Australie",
  "New Zealand": "Nouvelle-Zélande",
  "Brazil": "Brésil",
  "Mexico": "Mexique",
  "Argentina": "Argentine",
  "Cyprus": "Chypre",
  "Estonia": "Estonie",
  "Latvia": "Lettonie",
  "Lithuania": "Lituanie",
  "Luxembourg": "Luxembourg",
  "Malta": "Malte",
  "Iceland": "Islande",
  // Sports preferred playlist.
  "Preferred playlist": "Playlist préférée",
  "Try matching channels from this playlist first":
      "Essayer les chaînes correspondantes de cette playlist en premier",
  "Among comparable game matches, prefer this playlist, then your preferred countries, then video quality. Your game and team channel choices still come first. Other playlists remain available.":
      "Parmi les correspondances comparables, privilégiez cette playlist, puis vos pays préférés, puis la qualité vidéo. Vos choix de chaîne pour un match ou une équipe restent prioritaires. Les autres playlists restent disponibles.",
  "Your preferred playlist is unavailable or disabled. Other matching playlists will be used.":
      "Votre playlist préférée est indisponible ou désactivée. Les autres playlists correspondantes seront utilisées.",
  "No playlist preference": "Aucune préférence de playlist",
  "Disabled": "Désactivée",
  "No playlists yet": "Aucune playlist pour le moment",
  "Selected countries have equal priority. Match evidence comes first, then preferred playlist, country and video quality. Saved for this viewer.":
      "Les pays sélectionnés ont la même priorité. Les preuves du match passent en premier, puis la playlist préférée, le pays et la qualité vidéo. Enregistré pour ce profil.",
  "Rank countries equally": "Donner la même priorité à tous les pays",
  // Hide empty sports leagues.
  "Hide leagues with no games": "Masquer les ligues sans match",
  "Show only leagues with games on the selected day":
      "Afficher seulement les ligues avec des matchs le jour sélectionné",
  "Follows the selected day in Sports Trak. Leagues stay visible while schedules are loading or unavailable. Your saved leagues and their order are kept in Edit leagues. Saved for this viewer.":
      "Suit le jour sélectionné dans Sports Trak. Les ligues restent visibles pendant le chargement ou si les horaires sont indisponibles. Vos ligues et leur ordre sont conservés dans Modifier les ligues. Enregistré pour ce profil.",
  // Updater storage and download checks.
  "Free about {mb} MB and try again.": "Libérez environ {mb} Mo et réessayez.",
  "Could not check free storage. Restart VesperTV and try again.":
      "Impossible de vérifier l’espace libre. Redémarrez VesperTV et réessayez.",
  "Could not check the update size. Check for updates and try again.":
      "Impossible de vérifier la taille de la mise à jour. Recherchez les mises à jour et réessayez.",
  "Download failed. Please try again.":
      "Le téléchargement a échoué. Veuillez réessayer.",
  // IPTV cast portraits.
  "Metadata provided by TMDB.": "Métadonnées fournies par TMDB.",
  "No matching title found in your playlists.":
      "Aucun titre correspondant trouvé dans vos playlists.",
  "Skip intro": "Passer l'intro",
  "Skip recap": "Passer le résumé",
  "Skip credits": "Passer le générique",
  "Skip intro and credits button": "Bouton pour passer l'intro et le générique",
  "Skip intros and credits on TV show episodes":
      "Passer l'intro et le générique des épisodes",
  "On TV show episodes, a button skips the intro, the recap and the credits (or plays the next episode). Press OK while it shows. Times come from IntroDB (introdb.app), a free community database: it is asked with the show's IMDb id, season and episode number, nothing else.":
      "Sur les épisodes de séries, un bouton passe l'intro, le résumé et le générique (ou lance l'épisode suivant). Appuyez sur OK quand il s'affiche. Les temps viennent d'IntroDB (introdb.app), une base communautaire gratuite : on lui envoie seulement l'identifiant IMDb de la série, la saison et le numéro d'épisode.",
  "Betting odds": "Cotes de paris",
  "Show betting odds": "Afficher les cotes",
  "The line and over/under on game cards, more in the game stats":
      "La ligne et le total (over/under) sur les cartes de match, plus de détails dans les stats",
  "Show the line and over/under on games":
      "Afficher la ligne et le total des matchs",
  "Odds come with the scores (one sportsbook, mostly North American leagues) and show before and during a game. Display only: {app} never takes bets or links to a sportsbook. Saved for this viewer.":
      "Les cotes arrivent avec les scores (un seul bookmaker, surtout les ligues nord-américaines) et s'affichent avant et pendant un match. Affichage seulement : {app} ne prend aucun pari et ne renvoie vers aucun bookmaker. Enregistré pour ce profil.",
  "Moneyline": "Vainqueur",
  "Spread": "Écart",
  "Over": "Plus",
  "Under": "Moins",
  "Draw": "Nul",
  "Favourite": "Favori",
  "Total": "Total",
  "Betting odds · {book}": "Cotes · {book}",
};
