/// Italian UI strings, keyed by the English text in the code (see l10n.dart).
///
/// Standard Italian. TV labels are often narrow, so short forms are used on
/// purpose (AGG., G/V/P for standings, etc.). Keep every `{placeholder}`
/// exactly as in the key. `{s}` is an English-style plural "s" filled in by
/// the code; Italian plurals don't work that way (canale/canali), so those
/// strings are phrased to avoid it.
const Map<String, String> kIt = {
  "Discord": "Discord",
  "Direct support through Discord": "Supporto diretto su Discord",
  "Questions, help with setup, feature ideas and release news: join the VesperTV community on Discord.":
      "Domande, aiuto con la configurazione, idee e novità sulle versioni: unisciti alla community di VesperTV su Discord.",
  "VesperTV is free, with no ads. A coffee or a Supporter membership helps cover its costs.":
      "VesperTV è gratuito e senza pubblicità. Un caffè o un abbonamento Supporter aiuta a coprirne i costi.",
  "Show a test popup": "Mostra un popup di prova",
  "A sample goal alert for 8 seconds.":
      "Un avviso gol di esempio per 8 secondi.",
  "Guide": "Guida",
  "Live TV guide layout, full-screen video, compact rows":
      "Layout della guida, video a schermo intero, righe compatte",
  "{n} titles": "{n} titoli",
  "Open groups as expanded catalog": "Apri i gruppi come catalogo esteso",
  "Movies and TV Shows groups open the full poster grid instead of the rows.":
      "I gruppi Film e Serie TV aprono la griglia completa di locandine invece delle righe.",
  "Compact guide": "Guida compatta",
  "Shorter Timeline rows so more channels fit in the same space.":
      "Righe più basse nella timeline per mostrare più canali.",
  "Transparent popups": "Popup trasparenti",
  "Reminders and goal alerts lose their background and outline, keeping only the logo and text.":
      "Promemoria e avvisi gol perdono sfondo e contorno, mantenendo solo logo e testo.",
  "Use with playlist": "Usa con la playlist",
  "Save EPG URL": "Salva URL della guida",
  "Custom EPG URL saved.": "URL guida personalizzato salvato.",
  "Custom EPG URL cleared.": "URL guida personalizzato rimosso.",
  "Pick a playlist, then paste a third-party XMLTV link. Leave it blank to use the guide of that playlist. A channel is only filled in when the ids in the feed match the playlist.":
      "Scegli una playlist, poi incolla un link XMLTV di terze parti. Lascia vuoto per usare la guida della playlist. Un canale si compila solo se gli id della fonte corrispondono a quelli della playlist.",
  // Sports Trak quality preference (moved from the league bar).
  "Prefer higher-quality channels among game matches":
      "Preferisci i canali di qualità superiore tra quelli della partita",
  "On by default. Your saved channel choices still come first. Turn this off to keep the usual match order. Saved for this viewer.":
      "Attivo per impostazione predefinita. I canali scelti e salvati mantengono la priorità. Disattiva per mantenere il normale ordine delle corrispondenze. Salvato per questo profilo.",
  // Android phone player touch lock.
  "Lock touch controls": "Blocca i comandi touch",
  "Unlock touch controls": "Sblocca i comandi touch",
  "Touch controls locked": "Comandi touch bloccati",
  // Media Hub custom posters.
  "Add {imdb_id} or {tmdb_id} where the title goes.":
      "Aggiungi {imdb_id} o {tmdb_id} dove va il titolo.",
  "Custom posters": "Locandine personalizzate",
  "Custom posters off: Media Hub shows the sources' posters.":
      "Locandine personalizzate disattivate: Media Hub mostra le locandine delle fonti.",
  "Example: {url}": "Esempio: {url}",
  "Media Hub posters from a poster service":
      "Locandine di Media Hub da un servizio di locandine",
  "Poster address": "Indirizzo delle locandine",
  "Saved. Media Hub posters now come from this address.":
      "Salvato. Le locandine di Media Hub ora arrivano da questo indirizzo.",
  "Show Media Hub posters from a poster service of your choice, for example one that adds ratings. Paste its poster address with {imdb_id} (or {tmdb_id}) where the title goes; include your own key if the service needs one.":
      "Mostra le locandine di Media Hub dal servizio che preferisci, per esempio uno che aggiunge i voti. Incolla il suo indirizzo delle locandine con {imdb_id} (o {tmdb_id}) dove va il titolo; includi la tua chiave se il servizio la richiede.",
  "Turn off": "Disattiva",
  "When a title has no matching ID, its normal poster is shown. Leave empty to turn it off.":
      "Se un titolo non ha l'identificativo richiesto, viene mostrata la sua locandina normale. Lascia vuoto per disattivare.",
  // Media Hub experience (progressive sources, rows, discovery).
  "Add your TMDB key for collections and cast credits":
      "Aggiungi la tua chiave TMDB per collezioni e cast",
  "Airs {date}": "In onda {date}",
  "All sources": "Tutte le fonti",
  "Any source": "Qualsiasi fonte",
  "Auto-play preferred stream": "Riproduci automaticamente il flusso preferito",
  "Cast and credits": "Cast e crediti",
  "Collection": "Collezione",
  "Continue series": "Continua la serie",
  "Could not load credits.": "Impossibile caricare i crediti.",
  "Could not load this title. Try again.":
      "Impossibile caricare questo titolo. Riprova.",
  "Customize": "Personalizza",
  "Customize Media Hub": "Personalizza Media Hub",
  "Customize rows": "Personalizza righe",
  "Explore more": "Esplora altro",
  "Explore this genre": "Esplora questo genere",
  "Hide a row without disabling its playback source.":
      "Nascondi una riga senza disattivarne la fonte di riproduzione.",
  "Hide row": "Nascondi riga",
  "If no stream matches, choose one manually. Format and language information comes from your sources.":
      "Se nessun flusso corrisponde, scegline uno manualmente. Le informazioni su formato e lingua provengono dalle tue fonti.",
  "Leave empty to reset": "Lascia vuoto per ripristinare",
  "Loading": "Caricamento",
  "Loading recommendations…": "Caricamento consigli…",
  "Looking for streams…": "Ricerca flussi…",
  "Maximum quality": "Qualità massima",
  "More like this": "Altri simili",
  "No compatible source for this title. Add a playback source in Media Hub settings.":
      "Nessuna fonte compatibile per questo titolo. Aggiungi una fonte di riproduzione nelle impostazioni di Media Hub.",
  "No credits found.": "Nessun credito trovato.",
  "No results": "Nessun risultato",
  "No streams": "Nessun flusso",
  "Pin row": "Fissa riga",
  "Playback preferences": "Preferenze di riproduzione",
  "Prefer SDR": "Preferisci SDR",
  "Preferred source": "Fonte preferita",
  "Rename row": "Rinomina riga",
  "Results": "Risultati",
  "Retry recommendations": "Riprova i consigli",
  "Search sources": "Fonti di ricerca",
  "Show row": "Mostra riga",
  "Sources": "Fonti",
  "Sources · searching…": "Fonti · ricerca…",
  "Unavailable": "Non disponibile",
  "subtitles": "sottotitoli",
  // Sports matchup information and activation.
  "Key stats": "Statistiche chiave",
  "Latest goal": "Ultimo gol",
  "Last play": "Ultima azione",
  "Game situation": "Situazione della partita",
  "OK: watch here  ·  Hold: pick the channel":
      "OK: guarda qui  ·  Tieni premuto: scegli il canale",
  "Click: watch here  ·  Hold: pick the channel":
      "Clic: guarda qui  ·  Tieni premuto: scegli il canale",
  "Open full Live TV": "Apri TV in diretta completa",
  // Startup profile selector.
  "Launch with profiles selector": "Avvia con il selettore dei profili",
  "Choose a profile after the splash, before the app opens. Applies from the next start.":
      "Scegli un profilo dopo la schermata iniziale, prima di aprire l’app. Si applica dal prossimo avvio.",
  "Who is watching?": "Chi sta guardando?",
  "Choose your profile to get started.": "Scegli il tuo profilo per iniziare.",
  "Welcome, {name}": "Benvenuto, {name}",
  "Could not switch profile. Please try again.":
      "Impossibile cambiare profilo. Riprova.",

  "Sports Mode": "Modalità Sport",
  "Make Sports Trak your home, with your top five leagues at the side.":
      "Usa Sports Trak come pagina iniziale, con i tuoi primi cinque campionati a lato.",
  "Could not change Sports Mode. Try again.":
      "Impossibile cambiare la modalità Sport. Riprova.",
  // Media Hub source cards.
  "Enabled": "Attiva",
  "Catalogs from Cinemeta": "Cataloghi da Cinemeta",
  "Media server": "Server multimediale",
  "Tracker lists": "Liste di monitoraggio",
  "Catalogs only": "Solo cataloghi",
  "Streams only": "Solo flussi",
  "Catalogs + streams": "Cataloghi + flussi",
  "Provides video playback": "Fornisce la riproduzione video",
  "Refresh Media Hub after changing Other.":
      "Aggiorna Media Hub dopo aver modificato Altro.",
  "Playback sources": "Sorgenti di riproduzione",
  "These sources provide the video when you press Play.":
      "Queste sorgenti forniscono il video quando premi Riproduci.",
  "No playback sources yet.": "Nessuna sorgente di riproduzione.",
  "Catalogs & lists": "Cataloghi e liste",
  "Discover titles here; playback comes from your sources above.":
      "Scopri i titoli qui; la riproduzione usa le sorgenti qui sopra.",
  "Popular · New · Featured": "Popolari · Novità · In evidenza",
  "Catalogs for stream-only sources":
      "Cataloghi per sorgenti che offrono solo flussi",
  "Posters and episode details may still use Cinemeta when this is off.":
      "Locandine e dettagli degli episodi possono usare Cinemeta anche quando questa opzione è disattivata.",
  "Hold OK on Enabled to remove a source.":
      "Tieni premuto OK su Attiva per rimuovere una sorgente.",
  "Show under Other keeps a source behind the Other genre filter in Movies and TV Shows.":
      "Mostra in Altro colloca una sorgente nel filtro di genere Altro in Film e Serie TV.",

  "Remove from history": "Rimuovi dalla cronologia",
  "Automatically play the largest file":
      "Riproduci automaticamente il file più grande",
  "Use the largest known file size when starting a title. Resume keeps your selected stream.":
      "Scegli il file di dimensione nota maggiore all’avvio. La ripresa mantiene il flusso selezionato.",
  "Prefer highest quality": "Preferisci la qualità più alta",
  "Remind me for every game: {team}": "Ricordami ogni partita: {team}",
  "Stop team reminders: {team}": "Disattiva promemoria: {team}",
  "Remind me": "Ricordamelo",
  "Cancel reminder": "Annulla promemoria",
  "15 minutes before and at game time (while VesperTV is open)":
      "15 minuti prima e all’inizio della partita (con VesperTV aperto)",
  "Reminder set": "Promemoria impostato",
  "Reminder cancelled": "Promemoria annullato",
  "Could not save reminder.": "Impossibile salvare il promemoria.",
  "This game has already started.": "Questa partita è già iniziata.",
  "Your team: {home} vs {away}": "La tua squadra: {home} contro {away}",
  "Starts in 15 minutes": "Inizia tra 15 minuti",
  "Is about to start": "Sta per iniziare",

  "Display": "Schermo",
  "Match the TV to the video's frame rate and resolution":
      "Adatta il televisore alla frequenza dei fotogrammi e alla risoluzione del video",
  "Match frame rate": "Adatta frequenza fotogrammi",
  "Switches the TV to the video's frame rate a few seconds after it starts (50 Hz for UK and European channels, 24 Hz for films), for smooth motion. The screen goes black for a second or two while the TV switches; channels with the same rate don't switch again. Leaving the app gives the TV its own setting back.":
      "Porta il televisore alla frequenza dei fotogrammi del video pochi secondi dopo l’avvio (50 Hz per i canali britannici ed europei, 24 Hz per i film), per un movimento fluido. Lo schermo diventa nero per un secondo o due durante il cambio; i canali con la stessa frequenza non cambiano più. Uscendo dall’app il televisore torna alla sua impostazione.",
  "Only switch between 50 and 60 Hz": "Cambia solo tra 50 e 60 Hz",
  "Films at 24 frames per second keep the current rate, so fewer switches.":
      "I film a 24 fotogrammi al secondo mantengono la frequenza attuale: meno cambi.",
  "Match resolution": "Adatta risoluzione",
  "Switches the TV to the video's resolution (1080p, 4K…) so the TV does the upscaling. Off: this device scales every video to its current resolution.":
      "Porta il televisore alla risoluzione del video (1080p, 4K…) così l’upscaling lo fa il televisore. Disattivato: questo dispositivo scala ogni video alla sua risoluzione attuale.",
  "Stream HDR": "HDR dello stream",
  "No (SDR)": "No (SDR)",
  "Home": "Home",
  "Today's games": "Partite di oggi",
  "Recent channels": "Canali recenti",
  "Favourite channels": "Canali preferiti",
  "New movies": "Nuovi film",
  "New TV shows": "Nuove serie",
  'Series': "Serie TV",
  "Movie": "Film",
  "Move row up": "Sposta la riga su",
  "Move row down": "Sposta la riga giù",
  "Hide this row": "Nascondi questa riga",
  "Edit Home rows…": "Modifica righe della Home…",
  "Home rows": "Righe della Home",
  "Nothing here yet. Watch a channel, a movie or a show and it shows up on Home.":
      "Ancora niente. Guarda un canale, un film o una serie e comparirà nella Home.",
  "Native video surface (beta)": "Superficie video nativa (beta)",
  "Plays the picture the way native TV apps do, for HDR that looks washed out or green flashes under the guide (Fire TV Cube, NVIDIA Shield). Restart the app after changing it. If the picture is missing, in the wrong place or menus look wrong, turn it off and send us a log.":
      "Mostra l’immagine come le app TV native, per un HDR sbiadito o lampi verdi sotto la guida (Fire TV Cube, NVIDIA Shield). Riavvia l’app dopo averlo cambiato. Se l’immagine manca, è nel posto sbagliato o i menu appaiono male, disattivalo e inviaci un log.",
  "Close the app completely and open it again to apply this change.":
      "Chiudi completamente l’app e riaprila per applicare questa modifica.",
  "Green flicker fix (test)": "Correzione sfarfallio verde (test)",
  "For green flashes on the picture while the guide or a menu is over it (NVIDIA Shield). Unlike Compatibility video it keeps HDR. Applies from the next channel. If the guide or menus disappear behind the video, turn it off.":
      "Per i lampi verdi sull’immagine quando la guida o un menu è sopra (NVIDIA Shield). A differenza di Video compatibile mantiene l’HDR. Si applica dal canale successivo. Se la guida o i menu spariscono dietro il video, disattivalo.",
  'Automatic: on for this device.':
      'Automatico: attivo per questo dispositivo.',
  '1 hour': '1 ora',
  '{h} hours': '{h} ore',

  'Sort groups': 'Ordina gruppi',
  'Provider order': 'Ordine del fornitore',
  'Name A–Z': 'Nome A–Z',
  'Name Z–A': 'Nome Z–A',

  // ── Startup / catalog sync ───────────────────────────────────────────
  'Starting...': "Avvio…",
  'Content updated': "Contenuti aggiornati",
  'Startup failed:\n{bootstrapError}': "Avvio non riuscito:\n{bootstrapError}",
  'Retry': "Riprova",
  'Your catalog has never been fully synced.':
      "Il catalogo non è mai stato sincronizzato del tutto.",
  'Your catalog was last fully synced earlier today.':
      "Ultima sincronizzazione completa del catalogo: oggi, poco fa.",
  'Your catalog was last fully synced {days} day{s} ago.':
      "Ultima sincronizzazione completa del catalogo: {days} g fa.",
  'Update content now?': "Aggiornare i contenuti adesso?",
  'This can take a few minutes on a large catalog. Skipping opens the app with what\'s already cached.':
      "Con un catalogo grande può richiedere qualche minuto. Se salti, l'app si apre con ciò che è già in cache.",
  'Skip for now': "Non ora",
  'Update': "Aggiorna",
  'Loading movies & TV shows...': "Caricamento di film e serie…",
  'Connecting to server...': "Connessione al server…",
  'Updating Content': "Aggiornamento contenuti",
  '{done} / {total} categories': "{done} / {total} categorie",
  'This happens every few days to keep your catalog current — everyday launches open straight in.':
      "Succede ogni pochi giorni per tenere aggiornato il catalogo; negli altri giorni l'app si apre subito.",
  'Re-checks every visible category for new content. This can take a few minutes on a large catalog.':
      "Ricontrolla ogni categoria visibile in cerca di nuovi contenuti. Con un catalogo grande può richiedere qualche minuto.",
  'Cancel': "Annulla",

  // ── Multiview ────────────────────────────────────────────────────────
  'Multiview': "Multivista",
  'Layout': "Layout",
  '2 channels': "2 canali",
  '4 channels': "4 canali",
  '= audio — click a channel to switch':
      "= audio — clicca un canale per cambiare",
  'Reload': "Ricarica",
  'Change channel': "Cambia canale",
  'Remove': "Rimuovi",
  'Search channels...': "Cerca canali…",
  'Before you start': "Prima di iniziare",
  'Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn\'t, press OK on it and choose Reload.':
      "Ogni schermo della Multivista è una connessione separata al tuo provider. La tua lista deve consentire almeno tante connessioni quanti sono gli schermi aperti (vedi Connessioni max. in Gestione liste).\n\nSe due schermi condividono un account che consente una sola connessione, si scollegano a vicenda e si bloccano o vanno in buffering. Consiglio: usa canali di liste diverse, una per account.\n\nUno schermo bloccato si riavvia da solo. Se non succede, premi OK su di esso e scegli Ricarica.",
  'Don\'t show this again': "Non mostrare più",
  'OK': "OK",
  'Couldn\'t start that channel': "Impossibile avviare il canale",
  'Full screen': "Schermo intero",
  'Windowed': "In finestra",
  '4 screens': "4 schermi",
  '1 + 3 screens': "1 + 3 schermi",
  'Move to the big screen': "Sposta sullo schermo grande",
  'Swap mode': "Modalità scambio",
  'SWAP': "SCAMBIO",
  'Arrows swap · OK or Back to finish': "Frecce: scambia · OK o Indietro: fine",
  '2 screens': "2 schermi",
  '= audio — Select to switch, hold Select for options':
      "= audio — OK per cambiare, tieni premuto OK per le opzioni",
  'Pick a channel': "Scegli un canale",
  'No channels found': "Nessun canale trovato",
  'Open in Multiview': "Apri in Multivista",

  // ── Player ───────────────────────────────────────────────────────────
  'Recall — recently watched': "Recenti — visti di recente",
  'No other live channels watched yet this session.':
      "Nessun altro canale in diretta visto in questa sessione.",
  'Recall — go back to a recent channel': "Recenti — torna a un canale recente",
  'Remove from favorites': "Rimuovi dai preferiti",
  'Add to favorites': "Aggiungi ai preferiti",
  'Reload channel': "Ricarica canale",
  'Previous episode': "Episodio precedente",
  'Next episode': "Episodio successivo",
  'Ending now': "In chiusura",
  '{minutes} min left': "Mancano {minutes} min",
  'Back': "Indietro",
  'Fit to screen': "Adatta allo schermo",
  'Fill screen': "Riempi lo schermo",
  'Closed captions (CC) — if the channel broadcasts them':
      "Sottotitoli (CC) — se il canale li trasmette",
  'Up Next': "A seguire",
  'Playing in {countdown}s': "Riproduzione tra {countdown} s",
  'Playing now...': "Riproduzione…",
  'Play now': "Riproduci ora",
  'Dismiss': "Ignora",
  'Select a channel to start watching': "Scegli un canale per iniziare",
  'Switch to {p}: {name}': "Passa a {p}: {name}",
  'Switch to {playlistName}: {name}': "Passa a {playlistName}: {name}",
  'Technical details': "Dettagli tecnici",
  "This is a Dolby Vision video, and this device can't play this kind of Dolby Vision. Pick a version without DV (HDR10 or SDR) if your source has one.":
      "Questo video è in Dolby Vision e questo dispositivo non può riprodurre questo tipo di Dolby Vision. Scegli una versione senza DV (HDR10 o SDR) se la tua fonte ne offre una.",
  "This stream kept dropping and restarting, so playback was stopped. Try the channel again in a moment, or pick another one.":
      "Questo flusso continuava a interrompersi e a ripartire, quindi la riproduzione è stata fermata. Riprova il canale tra poco o scegline un altro.",
  'This device\'s video decoder couldn\'t play this stream — likely 4K HDR (HEVC 10-bit). If your provider offers an HD (non-4K) version of this channel or title, try that. If another app plays this stream on this device, please report it with a photo of the technical details below.':
      "Il decoder video di questo dispositivo non è riuscito a riprodurre questo flusso; probabilmente è 4K HDR (HEVC 10 bit). Se il tuo provider offre una versione HD (non 4K) di questo canale o titolo, prova quella. Se un'altra app riproduce questo flusso su questo dispositivo, segnalacelo con una foto dei dettagli tecnici qui sotto.",
  'Playback error:\n{raw}': "Errore di riproduzione:\n{raw}",
  "Server error {code}": "Errore del server {code}",
  "The provider's server had a problem. Try again in a moment.":
      "Il server del provider ha avuto un problema. Riprova tra un momento.",
  "The provider refused the stream: check that your account is active and not already in use on another device.":
      "Il provider ha rifiutato lo stream: verifica che il tuo account sia attivo e non già in uso su un altro dispositivo.",
  "The provider has no stream at this address: the channel or title may have been removed.":
      "Il provider non ha nessuno stream a questo indirizzo: il canale o il titolo potrebbe essere stato rimosso.",
  "The provider rejected the request.":
      "Il provider ha rifiutato la richiesta.",
  "Couldn't reach the provider's server. Check your internet connection, or the server may be down.":
      "Impossibile raggiungere il server del provider. Controlla la connessione a Internet, oppure il server potrebbe essere inattivo.",
  "Couldn't find the provider's server address. Check your internet connection or DNS settings, or try again later.":
      "Impossibile trovare l'indirizzo del server del provider. Controlla la connessione a Internet o le impostazioni DNS, oppure riprova più tardi.",
  'Subtitles': "Sottotitoli",
  "1 game": "1 partita",
  "{live} live": "{live} in diretta",
  "Leagues with games": "Campionati con partite",
  "All leagues": "Tutti i campionati",
  "{n} games": "{n} partite",
  "{n} games · {live} live": "{n} partite · {live} in diretta",
  "No games": "Nessuna partita",
  "Favourite networks": "Reti preferite",
  "Favourite this network": "Aggiungi questa rete ai preferiti",
  "Remove from favourite networks": "Rimuovi dalle reti preferite",
  "Networks": "Reti",
  "Other sports channels": "Altri canali sportivi",
  "On now": "In onda",
  "No channel matches these filters.":
      "Nessun canale corrisponde a questi filtri.",
  "No sports channels found in your playlists.":
      "Nessun canale sportivo trovato nelle tue playlist.",
  "Empty list: hold OK on any channel card to add it here.":
      "Lista vuota: tieni premuto OK su una scheda canale per aggiungerla qui.",
  "OK · Full screen   Hold OK · Pick a channel   Back · Stop":
      "OK · Schermo intero   Tieni OK · Scegli un canale   Indietro · Ferma",
  "OK · Preview   Hold OK · Pick a channel or add to a list":
      "OK · Anteprima   Tieni OK · Scegli un canale o aggiungilo a una lista",
  "See all": "Vedi tutto",
  "Update automatically": "Aggiorna automaticamente",
  "Live stream format: HLS": "Formato dello streaming live: HLS",
  "Off: MPEG-TS (default, fastest start). On: HLS, like the HLS option in TiviMate. Plays about 10 seconds further behind live, but hides servers that send live TV in bursts. Applies from the next channel.": "Disattivato: MPEG-TS (predefinito, avvio più rapido). Attivato: HLS, come l'opzione HLS di TiviMate. Va circa 10 secondi più indietro rispetto alla diretta, ma nasconde i server che inviano la TV in diretta a scatti. Vale dal canale successivo.",
  "On: when an update is due, it runs at launch without asking. Off: the app asks \"Update content now?\" first.":
      "Attivo: quando un aggiornamento è dovuto, parte all'avvio senza chiedere. Disattivo: l'app chiede prima «Aggiornare i contenuti ora?».",
  "Open on": "Apri su",
  "{section}. Where the app opens after starting. With \"Resume last channel in full screen\" on, the channel then plays in the background instead.":
      "{section}. Dove si apre l'app all'avvio. Con «Riprendi l'ultimo canale a schermo intero» attivo, il canale viene riprodotto in sottofondo.",
  "Subtitle size": "Dimensione sottotitoli",
  "Enter a name first": "Inserisci prima un nome",
  "Dolby Vision (profile {p}, no HDR10 fallback)":
      "Dolby Vision (profilo {p}, senza fallback HDR10)",
  "Dolby Vision (profile {p}, HDR10 compatible)":
      "Dolby Vision (profilo {p}, compatibile HDR10)",
  "Dolby Vision (profile {p}, HLG compatible)":
      "Dolby Vision (profilo {p}, compatibile HLG)",
  "Dolby Vision (profile {p})": "Dolby Vision (profilo {p})",
  "Extra small": "Molto piccola",
  "Small": "Piccola",
  "Normal": "Normale",
  "Large": "Grande",
  "Extra large": "Molto grande",
  'Off': "Disattivati",
  'Forced': "Forzati",
  'Online': 'Online',
  'Search online subtitles': 'Cerca sottotitoli online',
  'From your add-ons (Settings > Add-ons)':
      'Dai tuoi componenti (Impostazioni > Componenti aggiuntivi)',
  'Online subtitles': 'Sottotitoli online',
  'No subtitles found for this title.':
      'Nessun sottotitolo trovato per questo titolo.',
  "Couldn't download that subtitle. Try another.":
      'Impossibile scaricare questo sottotitolo. Provane un altro.',
  'Add-ons': 'Componenti aggiuntivi',
  'Online subtitles in more languages': 'Sottotitoli online in più lingue',
  'Remove {name}?': 'Rimuovere {name}?',
  "That link isn't a subtitle add-on (only subtitle add-ons are supported).":
      'Questo link non è un componente di sottotitoli (sono supportati solo quelli).',
  'That add-on is already in the list.': "Questo componente è già nell'elenco.",
  '{name} added.': '{name} aggiunto.',
  "Add-ons find subtitles online for movies and episodes, in many languages. They are free community services, separate from your provider — VesperTV only uses them for subtitles. Turn one on, then pick \"Search online subtitles\" in the player's Subtitles button.":
      'I componenti aggiuntivi trovano sottotitoli online per film ed episodi, in molte lingue. Sono servizi gratuiti della community, separati dal tuo provider — VesperTV li usa solo per i sottotitoli. Attivane uno, poi scegli «Cerca sottotitoli online» nel pulsante Sottotitoli del player.',
  'Subtitle add-ons': 'Componenti per sottotitoli',
  'Subtitles in 60+ languages from OpenSubtitles.org':
      'Sottotitoli in oltre 60 lingue da OpenSubtitles.org',
  'Hold OK to remove': 'Tieni premuto OK per rimuovere',
  'Add an add-on': 'Aggiungi un componente',
  'Add-on link (ends with manifest.json)':
      'Link del componente (termina con manifest.json)',
  'Only subtitle add-ons work here. When one is on, the title and episode you are watching are sent to it to find subtitles; nothing else is shared.':
      "Qui funzionano solo componenti per sottotitoli. Quando uno è attivo, gli vengono inviati il titolo e l'episodio che guardi per trovare i sottotitoli; non viene condiviso nient'altro.",
  'Looking for {language} subtitles…': "Cerco sottotitoli in {language}…",
  'No {language} subtitles for this title.':
      "Nessun sottotitolo in {language} per questo titolo.",
  'No {language} subtitles online for this title.':
      "Nessun sottotitolo in {language} online per questo titolo.",
  'Track {id}': "Traccia {id}",
  'Audio {n}': "Audio {n}",
  'Audio Track': "Traccia audio",
  'Audio track': "Traccia audio",

  // ── Catalog / browse ─────────────────────────────────────────────────
  'Sort': "Ordina",
  'Default': "Predefinito",
  'A to Z': "A-Z",
  'Z to A': "Z-A",
  'Rating (high to low)': "Voto (dal più alto)",
  'Date added/updated': "Data aggiunta/agg.",
  'Fetching TMDB release dates... {done}/{total}':
      "Recupero date di uscita da TMDB… {done}/{total}",
  'Added to Favorites': "Aggiunto ai preferiti",
  'Removed from Favorites': "Rimosso dai preferiti",
  'No items in this group.': "Nessun elemento in questo gruppo.",
  'Re-checks your M3U playlist URL(s) for new content.':
      "Ricontrolla l'URL delle tue liste M3U in cerca di nuovi contenuti.",
  'Set your playlist source in Settings first.':
      "Prima imposta la tua lista nelle Impostazioni.",
  'Continue Watching': "Continua a guardare",
  'Search': "Cerca",
  'Update content': "Agg. contenuti",
  'Update EPG now': "Agg. guida",
  'Settings': "Impostazioni",
  'No TV shows found. Pick a category on the left.':
      "Nessuna serie trovata. Scegli una categoria a sinistra.",
  'No channels found.': "Nessun canale trovato.",
  'Loading playlist...': "Caricamento lista…",
  'Failed to load playlist.': "Impossibile caricare la lista.",
  'Open Settings': "Apri Impostazioni",
  '{p}% watched': "Visto al {p}%",
  'Resume': "Riprendi",
  'Play': "Riproduci",
  'Restart': "Dall'inizio",
  'Failed to load episodes.': "Impossibile caricare gli episodi.",
  'No episodes found.': "Nessun episodio trovato.",
  'Season {season}': "Stagione {season}",
  'Expand catalog': "Catalogo completo",
  'Browse': "Sfoglia",
  'Playlist': "Lista",
  'Previous': "Precedente",
  'Next': "Successivo",
  'Loading...': "Caricamento…",
  'Loading…': "Caricamento…",
  'No recently added movies yet': "Ancora nessun film aggiunto di recente",
  'Loading movie categories...': "Caricamento categorie film…",
  'No recently added shows yet': "Ancora nessuna serie aggiunta di recente",
  'Loading TV show categories...': "Caricamento categorie serie…",
  "What's New": "Novità",

  // ── Search ───────────────────────────────────────────────────────────
  'Switch Profile': "Cambia profilo",
  'Restricted': "Limitato",
  'Search everything...': "Cerca ovunque…",
  'Search everything... (press OK to type)': "Cerca ovunque… (OK per scrivere)",
  'Still loading the full catalog in the background ({warmCatalogDone}/{warmCatalogTotal} categories) — some results may not show up yet.':
      "Il catalogo completo si sta ancora caricando in background ({warmCatalogDone}/{warmCatalogTotal} categorie); alcuni risultati potrebbero mancare.",
  'Search Live TV, Movies & TV Shows': "Cerca in TV in diretta, film e serie",
  'Recent searches': "Ricerche recenti",
  'Clear': "Cancella",
  'Live TV': "TV in diretta",
  'Movies': "Film",
  'TV Shows': "Serie TV",
  'Nothing found': "Nessun risultato",

  // ── Sports ───────────────────────────────────────────────────────────
  'Sports': "Sport",
  'this team': "questa squadra",
  'My Teams': "Le mie squadre",
  'Last channels': "Ultimi canali",
  '◀ ▶ tabs  ·  OK to watch  ·  Back to close':
      "◀ ▶ schede  ·  OK per guardare  ·  Indietro per chiudere",
  'None of your teams play today.': "Nessuna delle tue squadre gioca oggi.",
  'Follow teams from {tab} > Standings to see them here.':
      "Segui le squadre da {tab} > Classifica per vederle qui.",
  'No games from your leagues are live right now.':
      "Nessuna partita dei tuoi campionati è in diretta ora.",
  'Hold OK on a team to unfollow · on a game to pick the channel':
      "Tieni premuto OK su una squadra per non seguirla più · su una partita per scegliere il canale",
  'Add team': "Aggiungi squadra",
  'Follow one from Standings': "Seguine una dalla classifica",
  'Could not load': "Caricamento non riuscito",
  'Follow your teams to see them here': "Segui le tue squadre per vederle qui",
  'Follow another team': "Segui un'altra squadra",
  'Add team opens Standings: hold OK on a team to follow it.':
      "«Aggiungi squadra» apre la classifica: tieni premuto OK su una squadra per seguirla.",
  'This team could not be loaded. Check the connection.':
      "Impossibile caricare questa squadra. Controlla la connessione.",
  'Next 2 weeks': "Prossime 2 settimane",
  'No games in the next two weeks.':
      "Nessuna partita nelle prossime due settimane.",
  'vs': "vs",
  'at': "@",
  'Today {time}': "Oggi {time}",
  'Tomorrow {time}': "Domani {time}",
  'Last game: {opponent} · Final': "Ult. partita: {opponent} · Finale",
  'Last game: {result} {mine}-{other} {opponent}':
      "Ult. partita: {result} {mine}-{other} {opponent}",
  'LIVE': "LIVE",
  'Looking…': "Ricerca…",
  'TEAM': "SQUADRA",
  'Later today': "Più tardi oggi",
  'Tomorrow': "Domani",
  'Not played': "Non giocate",
  'Scheduled': "In programma",
  'Live now': "In diretta",
  'Final': "Finale",
  'All': "Tutto",
  'Edit leagues': "Campionati",
  'Scores hidden': "Risultati nascosti",
  'Scores shown': "Risultati visibili",
  'Yesterday': "Ieri",
  'Today': "Oggi",
  'Day': "Giorno",
  'OK: watch  ·  OK again: full screen  ·  Hold OK: stats  ·  ▼ all games':
      "OK: guarda  ·  OK di nuovo: schermo intero  ·  Tieni premuto OK: statistiche  ·  ▼ tutte le partite",
  'OK again on a game: full screen  ·  ▶❚❚: stop':
      "OK di nuovo su una partita: schermo intero  ·  ▶❚❚: ferma",
  'Standings': "Classifica",
  '{name} standings': "Classifica {name}",
  '{name} championship': "Campionato {name}",
  'No games on this day for your leagues':
      "Nessuna partita in questo giorno nei tuoi campionati",
  'Try another day, or add leagues with Edit leagues.':
      "Prova un altro giorno o aggiungi campionati con il pulsante Campionati.",
  'Live now  {count}': "In diretta  {count}",
  'Live': "In diretta",
  'Starts in {p}{p2}m': "Inizia tra {p}{p2} min",
  'Looking for the channel…': "Ricerca del canale…",
  'No channel found — OK to pick one':
      "Nessun canale trovato — OK per sceglierne uno",
  'Hold OK to pick or swap the channel':
      "Tieni premuto OK per scegliere o cambiare canale",
  'Hold OK: pick the channel  ·  ▶❚❚: watch here':
      "Tieni premuto OK: scegli il canale  ·  ▶❚❚: guarda qui",
  'Tap the game again: full screen  ·  Back: stop':
      "Tocca di nuovo la partita: schermo intero  ·  Indietro: ferma",
  'Tap: watch here  ·  Hold: pick the channel':
      "Tocca: guarda qui  ·  Tieni premuto: scegli il canale",
  'Play here': "Riproduci qui",
  '{channel} · plays at the top of {tab}':
      "{channel} · in onda in cima a {tab}",
  '▶❚❚: watch this game  ·  Back: playing game':
      "▶❚❚: guarda questa partita  ·  Indietro: partita in corso",
  'OK: full screen  ·  ▶❚❚ or Back: stop':
      "OK: schermo intero  ·  ▶❚❚ o Indietro: ferma",
  'Still looking for channels…': "Ricerca dei canali in corso…",
  'No channel found for this game': "Nessun canale trovato per questa partita",
  'On {matches} channel{s}': "Canali: {matches}",
  'Pick the channel': "Scegli il canale",
  'Choose a different channel': "Scegli un altro canale",
  'Search your channels — it can be remembered for this game or team':
      "Cerca tra i tuoi canali; la scelta può essere ricordata per questa partita o squadra",
  'Forget my pick': "Dimentica la mia scelta",
  'Go back to the automatic match': "Torna alla scelta automatica",
  'Remember this channel?': "Ricordare questo canale?",
  'Just this game': "Solo questa partita",
  'Best for channels named after one game':
      "Ideale per canali col nome di una partita",
  'Always for the {shortName}': "Sempre per {shortName}",
  'Best for a regular channel, like a regional network':
      "Ideale per un canale fisso, come una rete regionale",
  'Leagues': "Campionati",
  'Save': "Salva",
  'Pick the channel for {title}': "Scegli il canale per {title}",
  'Search channels': "Cerca canali",
  'No channels match "{query}"': "Nessun canale corrisponde a «{query}»",
  '{results}{p} channels': "{results}{p} canali",
  '{group} · Now: {now}': "{group} · Ora: {now}",
  'Preseason': "Precampionato",
  'Pick a league above, then hold OK on a team to follow it. Back returns to My Teams.':
      "Scegli un campionato in alto, poi tieni premuto OK su una squadra per seguirla. Indietro torna a Le mie squadre.",
  'Standings could not be loaded. Check the connection.':
      "Impossibile caricare la classifica. Controlla la connessione.",
  'switch conference': "cambia conference",
  'switch table': "cambia tabella",
  'Hold OK on a team to follow it (My Teams)':
      "Tieni premuto OK su una squadra per seguirla (Le mie squadre)",
  'Your pick': "La tua scelta",
  'Found by its name': "Trovato dal nome",
  'Found in the guide': "Trovato nella guida",
  "Team's channel, no guide listing": "Canale della squadra, non nella guida",
  "Broadcaster, no guide listing": "Emittente, non nella guida",
  "Only on a hidden channel": "Solo su un canale nascosto",
  "Not in your guide yet": "Non ancora nella tua guida",
  "On a hidden channel — OK to pick one":
      "Su un canale nascosto — OK per sceglierne uno",
  "Not in your guide yet — OK to pick one":
      "Non ancora nella tua guida — OK per sceglierne uno",
  "Only found on {channel}, which is hidden in your lists.":
      "Trovato solo su {channel}, che è nascosto nelle tue liste.",
  "Your guide doesn't cover this game's time yet. Update the guide closer to the game.":
      "La tua guida non copre ancora l'orario di questa partita. Aggiorna la guida più vicino alla partita.",
  "No channel name or guide listing names this game.":
      "Nessun nome di canale né programma della guida cita questa partita.",
  'Some scores could not be loaded. Check the connection.':
      "Alcuni risultati non sono stati caricati. Controlla la connessione.",
  'Unfollow': "Non seguire più",
  'Follow': "Segui",
  'Remove from My Teams': "Rimuovi da Le mie squadre",
  'Add to My Teams — their games show first in {tab}':
      "Aggiungi a Le mie squadre: le loro partite appaiono per prime in {tab}",
  // Results (W/L/D = won/lost/draw) and standings columns.
  'W': "V",
  'L': "P",
  'D': "N",
  'T': "N",
  'GP': "G",
  'GD': "DR",
  'PTS': "PT",
  'OTL': "PS",
  'DIFF': "DIFF",
  'STRK': "SERIE",
  'L10': "ULT10",
  'REC': "V-P",
  'PF': "PF",
  'PA': "PS",
  'HOME': "CASA",
  'AWAY': "TRASF",
  'PCT': "PCT",
  'GB': "DIST",

  // ── TV home ──────────────────────────────────────────────────────────
  'TV': "TV",
  'Favorites': "Preferiti",
  'Favourites': "Preferiti",
  'Remove from Favourites': "Rimuovi dai preferiti",
  'Add to Favourites': "Aggiungi ai preferiti",
  'Cancel Hide': "Annulla nascondi",
  'Hide Group': "Nascondi gruppo",
  'Move Up / Down': "Sposta su / giù",
  "Show": "Mostra",
  "Hide": "Nascondi",
  "Hidden here · {n} groups": "Nascosta qui · {n} gruppi",
  "At least one playlist stays shown.": "Almeno una playlist resta visibile.",
  "{name} hidden in {tab}": "{name} nascosta in {tab}",
  "{name} shown in {tab}": "{name} visibile in {tab}",
  "Playlists": "Playlist",
  "Jump to playlist": "Vai alla playlist",
  "{n} groups": "{n} gruppi",
  "Background video": "Video in sottofondo",
  "Mute": "Disattiva audio",
  "Unmute": "Riattiva audio",
  "Show under Other": "Mostra in Altro",
  "On: this source only appears behind the Other genre filter (Movies and TV Shows). Off: in the main rows. Press Refresh in Media Hub after changing this.":
      "Attivo: questa fonte compare solo dietro il filtro di genere Altro (Film e Serie TV). Disattivo: nelle righe principali. Premi Aggiorna in Media Hub dopo averlo cambiato.",
  "Use the Other filter in Media Hub > Movies / TV Shows > Genre to see this source.":
      "Usa il filtro Altro in Media Hub > Film / Serie TV > Genere per vedere questa fonte.",
  "Back to main": "Torna al principale",
  "Compatibility video": "Video compatibile",
  "Turn this on if the picture shows twice, in the wrong size or as coloured stripes (older Fire TV sticks). Applies from the next channel. On by default on Android 7 and older.":
      "Attivalo se l'immagine appare doppia, della dimensione sbagliata o a strisce colorate (vecchie chiavette Fire TV). Vale dal canale successivo. Attivo di default su Android 7 e precedenti.",
  "Hide the live picture behind other pages":
      "Nascondi l'immagine in diretta dietro le altre pagine",
  "A live channel keeps playing behind {tab}, Settings and Search. Some Fire TV sticks keep showing its picture on top of those pages. Turn this on if that happens: the sound keeps going, only the picture is hidden until you go back. Updating the device's software (Fire TV: Settings > My Fire TV > About > Check for Updates) may fix it too.":
      "Un canale in diretta continua dietro {tab}, Impostazioni e Cerca. Alcune chiavette Fire TV continuano a mostrare la sua immagine sopra quelle pagine. Attivalo se succede: l'audio continua, solo l'immagine viene nascosta finché non torni indietro. Aggiornare il software del dispositivo (Fire TV: Impostazioni > La mia Fire TV > Informazioni > Verifica aggiornamenti) può risolvere anche questo.",
  'Go to row': "Vai alla fila",
  "Typing a server address and password with a remote is painful. Scan this code with your phone camera and sign in there — the details appear here for you to check and connect.":
      "Digitare l'indirizzo di un server e una password con il telecomando è scomodo. Scansiona questo codice con la fotocamera del telefono e accedi lì: i dati compaiono qui per verificarli.",
  "Check the details here, then press Connect.":
      "Controlla i dati qui, poi premi Collega.",
  "{n} other catalogs": "{n} altri cataloghi",
  "Use the Other filter in Media Hub > Movies > Genre to see this content.":
      "Usa il filtro Altri in Media Hub > Film > Genere per vedere questi contenuti.",
  "Backup & restore": "Backup e ripristino",
  "Save everything to a file on this device":
      "Salva tutto in un file su questo dispositivo",
  "Back up now": "Esegui backup ora",
  "Playlists, favourites, profiles, progress and settings, saved to {path}":
      "Playlist, preferiti, profili, avanzamento e impostazioni, salvati in {path}",
  "Automatic backup": "Backup automatico",
  "Once a week, when VesperTV starts. Keeps the last {n}.":
      "Una volta alla settimana, all'avvio di VesperTV. Conserva gli ultimi {n}.",
  "Restore from a file": "Ripristina da un file",
  "Pick a backup file, e.g. after reinstalling VesperTV":
      "Scegli un file di backup, ad esempio dopo aver reinstallato VesperTV",
  "Backups": "Backup",
  "No backups yet.": "Nessun backup per ora.",
  "Backups include your playlist logins. Keep the files private.":
      "I backup contengono le credenziali delle tue playlist. Tieni i file privati.",
  "Manual": "Manuale",
  "Restore this backup": "Ripristina questo backup",
  "Restore": "Ripristina",
  "Restore backup?": "Ripristinare il backup?",
  "Everything on this device (playlists, favourites, profiles, settings) is replaced by the backup from {from}. Your current setup is saved as an automatic backup first. VesperTV closes afterwards.":
      "Tutto ciò che è su questo dispositivo (playlist, preferiti, profili, impostazioni) viene sostituito dal backup del {from}. La configurazione attuale viene prima salvata come backup automatico. Poi VesperTV si chiude.",
  "the chosen file": "il file scelto",
  "Backup restored": "Backup ripristinato",
  "Backup saved to {path}": "Backup salvato in {path}",
  "Backup failed: {error}": "Backup non riuscito: {error}",
  "VesperTV needs storage access to save backups.":
      "VesperTV ha bisogno dell'accesso alla memoria per salvare i backup.",
  "Couldn't read the backup folder: {error}":
      "Impossibile leggere la cartella dei backup: {error}",
  "Couldn't read this backup: {error}":
      "Impossibile leggere questo backup: {error}",
  "Couldn't delete this backup.": "Impossibile eliminare questo backup.",
  "This device has no file picker. Copy the backup into {path} on this device instead.":
      "Questo dispositivo non ha un selettore di file. Copia il backup in {path} su questo dispositivo.",
  "This file is not a VesperTV backup.":
      "Questo file non è un backup di VesperTV.",
  "Up / Down moves {name}. OK when done.":
      "Su / Giù sposta {name}. OK per finire.",
  "Mix playlists in Favourites": "Unisci le playlist nei preferiti",
  "TV, Movies and TV Shows favourites from every playlist in one A-Z list, instead of one list per playlist.":
      "I preferiti di TV, Film e Serie TV di tutte le playlist in un unico elenco dalla A alla Z, invece di un elenco per playlist.",
  'Move to Top': "Sposta in cima",
  'Unhide this channel': "Mostra di nuovo il canale",
  'Hide this channel': "Nascondi questo canale",
  'Double': "Doppio",
  'for groups': "per i gruppi",
  'Exit and free up this login?': "Uscire e liberare questo account?",
  'This disconnects your login here so it can be used on another device, then fully closes VesperTV. Your channels/movies will need to reload next time you open it.':
      "Disconnette qui il tuo account, così può essere usato su un altro dispositivo, poi chiude del tutto VesperTV. Canali e film dovranno ricaricarsi alla prossima apertura.",
  'Exit': "Esci",
  'Exit {appName}?': "Uscire da {appName}?",
  'Are you sure you want to exit {appName}?':
      "Vuoi davvero uscire da {appName}?",
  'Stay': "Resta",
  'History': "Cronologia",
  'No channels watched yet.': "Nessun canale guardato finora.",
  'Update Content': "Agg. contenuti",
  'Minimize': "Riduci a icona",
  'Close': "Chiudi",
  'Disable and exit': "Disattiva ed esci",
  'Long-press a group elsewhere to favorite the whole thing.':
      "Tieni premuto OK su un gruppo altrove per aggiungerlo tutto ai preferiti.",
  'Nothing playing': "Nessuna riproduzione",
  'Click to resume': "Clicca per riprendere",
  'Filter channels in this group...': "Filtra i canali del gruppo…",
  'Close filter': "Chiudi filtro",
  'Hidden — find it again in Settings > Playlist Manager > Hidden Channels':
      "Nascosto: lo ritrovi in Impostazioni > Gestione liste > Canali nascosti",
  'Unhidden': "Di nuovo visibile",
  'No favorited movies or TV shows yet.\nHold Select on a poster to add one.':
      "Ancora nessun film o serie nei preferiti.\nTieni premuto OK su una locandina per aggiungerne uno.",
  'No favorited movies yet.': "Ancora nessun film nei preferiti.",
  'No favorited TV shows yet.': "Ancora nessuna serie nei preferiti.",
  'No favorite channels yet — press Down while watching one to add it.':
      "Ancora nessun canale preferito: premi Giù mentre ne guardi uno per aggiungerlo.",
  'Updating…': "Aggiornamento…",
  'No program data': "Nessun palinsesto",
  'No program data available': "Palinsesto non disponibile",
  'Next: {title} ({p})': "Dopo: {title} ({p})",
  'Focus a program to see details':
      "Seleziona un programma per vedere i dettagli",
  'Space': "Spazio",
  'Loading EPG…': "Caricamento guida…",

  // ── Welcome ──────────────────────────────────────────────────────────
  'Hey beautiful Human,': "Ciao, splendido umano,",
  'Hey beautiful Human': "Ciao, splendido umano",
  'Welcome to VesperTV': "Benvenuto in VesperTV",
  'Add your first playlist?': "Aggiungere la tua prima lista?",
  'Add a playlist to kick things off, or skip for now if you just want to browse and discover the app without content.':
      "Aggiungi una lista per cominciare, oppure salta per ora se vuoi solo esplorare l'app senza contenuti.",

  // ── Add playlist ─────────────────────────────────────────────────────
  'Add Playlist': "Aggiungi lista",
  'Paste some text first.': "Prima incolla del testo.",
  "Couldn't find anything usable in that text.":
      "Niente di utilizzabile in quel testo.",
  'Received from your phone — check the details, then press Add Playlist.':
      "Ricevuto dal telefono: controlla i dati, poi premi «Aggiungi lista».",
  'Scan the code with your phone and send the form first.':
      "Prima scansiona il codice col telefono e invia il modulo.",
  'Playlist name is required.': "Il nome della lista è obbligatorio.",
  'Server, username, and password are all required.':
      "Server, nome utente e password sono obbligatori.",
  'M3U playlist URL is required.': "L'URL della lista M3U è obbligatorio.",
  'Playlist updated.': "Lista aggiornata.",
  'Playlist added.': "Lista aggiunta.",
  'Download content': "Scarica contenuti",
  'This provider has a large catalog. Download everything in the background, or choose which groups to include first?':
      "Questo provider ha un catalogo grande. Scaricare tutto in background o scegliere prima quali gruppi includere?",
  'Choose Groups First': "Scegli i gruppi",
  'Download All': "Scarica tutto",
  'Edit Playlist': "Modifica lista",
  'Playlist source': "Origine della lista",
  'M3U URL': "URL M3U",
  'Xtream Codes': "Xtream Codes",
  'Smart Add': "Aggiunta smart",
  'From phone': "Dal telefono",
  'Playlist name': "Nome della lista",
  'Name': "Nome",
  'e.g. My Provider, or 8kStrong': "es. Il mio provider, o 8kStrong",
  'M3U Playlist URL': "URL della lista M3U",
  'EPG (XMLTV) URL': "URL della guida (XMLTV)",
  'Paste the message your provider sent you — we\'ll pull out the server, username, and password.':
      "Incolla il messaggio che ti ha mandato il provider: ne ricaviamo server, nome utente e password.",
  'Paste provider message': "Incolla messaggio del provider",
  'Parse': "Analizza",
  'Confirm the server': "Conferma il server",
  'No server URL found in that text — enter it below.':
      "Nessun URL del server in quel testo: inseriscilo qui sotto.",
  'Server URL (e.g. http://host:port)':
      "URL del server (es. http://host:porta)",
  'Username': "Nome utente",
  'Password': "Password",
  'Custom EPG (XMLTV) URL — optional':
      "URL guida personalizzata (XMLTV) — facoltativo",
  'Leave blank to use the panel\'s own xmltv.php. Set this if your provider\'s EPG is empty or unreliable (e.g. a third-party feed like EPGgenius) — it only fills in a channel if that feed\'s ids match this panel\'s.':
      "Lascia vuoto per usare l'xmltv.php del pannello. Compilalo se la guida del tuo provider è vuota o poco affidabile (es. una fonte esterna come EPGgenius); un canale viene compilato solo se gli ID di quella fonte coincidono con quelli del pannello.",
  'Paste different text': "Incolla un altro testo",
  'Status': "Stato",
  'Failed to add playlist: {p}': "Impossibile aggiungere la lista: {p}",
  'Save Changes': "Salva modifiche",
  'Fill in the form on the left, then press {p} above.':
      "Compila il modulo a sinistra, poi premi «{p}» in alto.",
  'Unexpected Xtream API response': "Risposta inattesa dell'API Xtream",
  'Invalid Xtream username/password':
      "Nome utente o password Xtream non validi",
  'Xtream account is not active (status: {status})':
      "L'account Xtream non è attivo (stato: {status})",

  // ── Phone pairing ────────────────────────────────────────────────────
  'Code expired': "Codice scaduto",
  'Add from your phone': "Aggiungi dal telefono",
  'Typing a long password with a remote is painful. Scan this code with your phone camera and fill in the form there — it appears here for you to check and add.':
      "Scrivere una password lunga col telecomando è una fatica. Scansiona questo codice con la fotocamera del telefono e compila lì il modulo: comparirà qui per controllarlo e aggiungerlo.",
  'Scan with your phone (mobile data is fine).':
      "Scansiona col telefono (vanno bene anche i dati mobili).",
  'Connect your phone to the same Wi-Fi as this TV, then scan.':
      "Collega il telefono allo stesso Wi-Fi di questa TV, poi scansiona.",
  'Fill in the form and tap Send to TV.':
      "Compila il modulo e tocca «Send to TV».",
  'Check the details here, then press Add Playlist.':
      "Controlla i dati qui, poi premi «Aggiungi lista».",
  'Waiting for your phone…': "In attesa del telefono…",
  'Or open on the phone:': "Oppure apri sul telefono:",
  'Your details are encrypted on the phone; the relay only passes along scrambled data and deletes it.':
      "I tuoi dati vengono cifrati sul telefono; il relay inoltra solo dati cifrati e poi li cancella.",
  'New code': "Nuovo codice",
  'Phone on this Wi-Fi? Use the Wi-Fi code':
      "Telefono su questo Wi-Fi? Usa il codice Wi-Fi",
  'Phone not on this Wi-Fi? Use the other code':
      "Telefono non su questo Wi-Fi? Usa l'altro codice",

  // ── Channel linking / EPG matching ───────────────────────────────────
  'Add and enable a second playlist first — a link connects a channel on one playlist to its equivalent on another.':
      "Prima aggiungi e attiva una seconda lista: un collegamento unisce un canale di una lista al suo equivalente in un'altra.",
  'Auto-Pair Channels': "Abbina auto.",
  'Unpair Channels': "Separa canali",
  'Reviewing {reviewFilter} auto-paired channel{s} — type to search all instead':
      "Revisione dei canali abbinati auto. ({reviewFilter}): scrivi per cercare in tutti",
  'Search your channels': "Cerca tra i tuoi canali",
  'Not linked': "Non collegato",
  'Linked channel no longer available':
      "Il canale collegato non è più disponibile",
  'Linked to {p}: {name}': "Collegato a {p}: {name}",
  'Clear link': "Rimuovi collegamento",
  'Link "{name}"': "Collega «{name}»",
  'Search other playlists\' channels': "Cerca tra i canali delle altre liste",
  'No matches.': "Nessuna corrispondenza.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" first so there\'s a channel directory to match against.':
      "Nessuna guida caricata in questa sessione: esegui prima «Agg. guida» per avere un elenco di canali.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" above first so there\'s a channel directory to search.':
      "Nessuna guida caricata in questa sessione: esegui prima «Agg. guida» (in alto) per avere un elenco di canali.",
  'Assigned: {p}': "Assegnato: {p}",
  'Matched automatically': "Abbinato automaticamente",
  'Clear assignment': "Rimuovi assegnazione",
  'Assign "{channelName}"': "Assegna «{channelName}»",
  'Search the EPG feed\'s channels': "Cerca tra i canali della guida",
  'No EPG feed has been loaded yet this app session — go back and run "Update EPG Now" first.':
      "Nessuna guida caricata in questa sessione: torna indietro ed esegui prima «Agg. guida».",
  'Now: {title}': "Ora: {title}",
  'No current program data': "Nessun programma in corso",
  'Channels are pairing, please wait…':
      "Abbinamento dei canali in corso, attendi…",
  'No new matches found — anything still unmatched needs a manual pick.':
      "Nessuna nuova corrispondenza: il resto va scelto a mano.",
  'Paired {paired} channel{s} automatically.':
      "Canali abbinati automaticamente: {paired}.",
  'Review': "Rivedi",
  'Continue': "Continua",
  'Nothing was auto-paired — there\'s nothing to undo.':
      "Nessun abbinamento automatico: niente da annullare.",
  'Undo {autoPairedCount} automatic pairing{s}? Anything you\'ve set by hand is kept.':
      "Annullare gli abbinamenti automatici ({autoPairedCount})? Ciò che hai impostato a mano resta.",
  'Unpair': "Separa",

  // ── Check for updates ────────────────────────────────────────────────
  'Couldn\'t open the download link.':
      "Impossibile aprire il link di download.",
  'Allow installing updates': "Consenti l'installazione degli aggiornamenti",
  'Android needs one-time permission for VesperTV to install an update it downloaded. The next screen is Android\'s own settings — turn the toggle on, then come back here and press Install again.':
      "Android richiede un permesso una tantum perché VesperTV installi un aggiornamento scaricato. La schermata successiva è nelle impostazioni di Android: attiva l'opzione, poi torna qui e premi di nuovo Installa.",
  'Check for Updates': "Cerca aggiornamenti",
  'Current version: —': "Versione attuale: —",
  'Current version: {currentVersion}': "Versione attuale: {currentVersion}",
  'Checking...': "Verifica…",
  'You\'re on the latest version.': "Hai l'ultima versione.",
  'Check Again': "Ricontrolla",
  'Version {version} is available': "È disponibile la versione {version}",
  'Open Download Page': "Apri pagina di download",
  'Opens in your browser — unzip the download and run VesperTV.exe to update, replacing the old folder.':
      "Si apre nel browser: estrai il file scaricato e avvia VesperTV.exe per aggiornare, sostituendo la cartella precedente.",
  'Download & Install': "Scarica e installa",
  'Downloading update... {p}%': "Download aggiornamento… {p}%",
  'Download complete.': "Download completato.",
  'Install': "Installa",
  'Android will ask you to confirm the install — that\'s normal, not every app can skip it.':
      "Android ti chiederà di confermare l'installazione: è normale, non tutte le app possono saltare questo passaggio.",
  'Something went wrong: {p}': "Qualcosa è andato storto: {p}",
  'unknown error': "errore sconosciuto",
  'Try Again': "Riprova",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minute.':
      "GitHub sta limitando temporaneamente i controlli da questa rete: riprova tra circa {n} minuto.",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minutes.':
      "GitHub sta limitando temporaneamente i controlli da questa rete: riprova tra circa {n} minuti.",
  'GitHub is temporarily rate-limiting update checks from this network — try again shortly.':
      "GitHub sta limitando temporaneamente i controlli da questa rete: riprova tra poco.",

  // ── EPG settings ─────────────────────────────────────────────────────
  'No EPG URL set yet — add a playlist first.':
      "Nessun URL della guida: prima aggiungi una lista.",
  'Cache cleared.': "Cache svuotata.",
  'EPG': "Guida (EPG)",
  'General': "Generale",
  'EPG Matching': "Abbin. guida",
  'Channel Pairing': "Abbin. canali",
  'Auto-refresh interval': "Intervallo di agg. automatico",
  '{p} hours': "{p} ore",
  'EPG never updated': "Guida mai aggiornata",
  'EPG last updated: {p}': "Ultimo agg. della guida: {p}",
  'Update EPG Now': "Agg. guida",
  'Clear Cache': "Svuota cache",
  'Clears the cached EPG and catalog data — playlist source, favorites, and group visibility are kept.':
      "Svuota la guida e il catalogo in cache; origine delle liste, preferiti e visibilità dei gruppi restano.",
  'Fixes a channel with no program data by manually assigning it to an entry in the loaded EPG feed — useful when a provider\'s own id doesn\'t match a third-party source.':
      "Sistema un canale senza palinsesto assegnandolo a mano a una voce della guida caricata; utile quando l'ID del provider non coincide con una fonte esterna.",
  'Links a channel on one playlist to its equivalent on another. If a live channel fails to load, or you switch to it yourself from the player, playback can fall back to the paired channel on the other playlist instead.':
      "Collega un canale di una lista al suo equivalente in un'altra. Se un canale in diretta non si carica, o se cambi tu dal lettore, la riproduzione può passare al canale abbinato dell'altra lista.",

  // ── General settings ─────────────────────────────────────────────────
  'Clear search & channel history?':
      "Cancellare la cronologia di ricerche e canali?",
  'Removes your recent searches and the History list of live channels.':
      "Rimuove le ricerche recenti e la cronologia dei canali in diretta.",
  'Search and channel history cleared.':
      "Cronologia di ricerche e canali cancellata.",
  'Clear Movies & TV Shows history?':
      "Cancellare la cronologia di film e serie?",
  'Removes Continue Watching and the saved progress of every movie and episode.':
      "Rimuove Continua a guardare e i progressi salvati di ogni film ed episodio.",
  'Movies & TV Shows history cleared.':
      "Cronologia di film e serie cancellata.",
  'Language': "Lingua",
  'Follows the device language': "Segue la lingua del dispositivo",
  'Automatic': "Automatica",
  'Startup': "Avvio",
  'Resume last channel in full screen':
      "Riprendi l'ultimo canale a schermo intero",
  'Opens the last live channel full screen after the splash.':
      "Apre l'ultimo canale in diretta a schermo intero dopo la schermata iniziale.",
  'Resume last channel with the guide open':
      "Riprendi l'ultimo canale con la guida aperta",
  'Plays the last live channel in the small preview, with the channel list.':
      "Riproduce l'ultimo canale in diretta nella piccola anteprima, con l'elenco dei canali.",
  'Both off: nothing plays at startup (a "Hold > to resume" reminder instead).':
      "Entrambi disattivati: all'avvio non parte nulla (al suo posto un promemoria «Tieni premuto > per riprendere»).",
  'Tabs': "Schede",
  'Hide Movies and TV Shows': "Nascondi Film e Serie TV",
  'Removes both tabs and their search results, e.g. if you watch movies and shows elsewhere.':
      "Rimuove le due schede e i relativi risultati di ricerca, ad es. se guardi film e serie altrove.",
  'Favorite channels are in the TV tab, under Favourites.':
      "I canali preferiti sono nella scheda TV, sotto Preferiti.",
  'Show the Multiview tip': "Mostra il consiglio Multivista",
  'The connections reminder shown when opening Multiview.':
      "Il promemoria sulle connessioni all'apertura della Multivista.",
  'Resume reminder': "Promemoria di ripresa",
  'Show the "Hold > to resume" reminder':
      "Mostra il promemoria «Tieni premuto > per riprendere»",
  'The pill at the bottom while a channel plays in the background. Off: hidden.':
      "La pillola in basso mentre un canale è in riproduzione in background. Disattivato: nascosta.",
  'The pill at the bottom while a channel plays in the background. Off: hidden — holding Right still resumes.':
      "La pillola in basso mentre un canale è in riproduzione in background. Disattivato: nascosta; tenere premuto Destra riprende comunque.",
  'Clear search & channel history': "Cancella cronologia di ricerche e canali",
  'Recent searches and the live channel History':
      "Ricerche recenti e cronologia dei canali in diretta",
  'Clear Movies & TV Shows history': "Cancella cronologia di film e serie",
  'Continue Watching and saved progress':
      "«Continua a guardare» e progressi salvati",

  // ── Group management / hidden channels ───────────────────────────────
  'Leave group selection?': "Uscire dalla selezione dei gruppi?",
  'Your show/hide choices are saved, and anything still visible will start downloading — same as pressing Done.':
      "Le tue scelte mostra/nascondi vengono salvate e tutto ciò che è visibile inizierà a scaricarsi, come premendo Fatto.",
  'Leave': "Esci",
  'Save playlist?': "Salvare la lista?",
  'Your playlist will be saved with the selected groups. You can always add or remove groups later in Settings > Group Management.':
      "La lista sarà salvata con i gruppi scelti. Potrai sempre aggiungere o togliere gruppi in Impostazioni > Gestione gruppi.",
  'Confirm': "Conferma",
  'Group Management': "Gestione gruppi",
  'Done': "Fatto",
  'If you are done selecting your groups, press Confirm below.\n\nIf you are not done yet, press Left to go back to your categories.':
      "Se hai finito di scegliere i gruppi, premi Conferma qui sotto.\n\nAltrimenti premi Sinistra per tornare alle categorie.",
  'No categories yet — load a playlist first.':
      "Nessuna categoria: prima carica una lista.",
  'Search groups (starts with)': 'Cerca gruppi (inizia con)',
  '{shown} of {total} groups': '{shown} di {total} gruppi',
  'Show results': 'Mostra risultati',
  'Hide results': 'Nascondi risultati',
  'No groups start with "{query}".': 'Nessun gruppo inizia con «{query}».',
  'Show All': "Mostra tutto",
  'Hide All': "Nascondi tutto",
  'Hidden channels': "Canali nascosti",
  'No channels are individually hidden. Hide one from its row in the Live TV list.':
      "Nessun canale nascosto singolarmente. Nascondine uno dalla sua riga nell'elenco TV in diretta.",
  'Unhide': "Mostra",
  'Show group': "Mostra gruppo",
  'Hide group': "Nascondi gruppo",

  // ── Playlist manager / priority ──────────────────────────────────────
  'Playlist Manager': "Gestione liste",
  'Playlist Priority': "Priorità liste",
  'Which playlist\'s groups show first, per tab':
      "Quale lista mostra prima i suoi gruppi, per scheda",
  'No playlists yet — tap "Add Playlist" above to get started.':
      "Ancora nessuna lista: premi «Aggiungi lista» in alto per iniziare.",
  'Delete playlist?': "Eliminare la lista?",
  'This removes "{name}"\'s login and cached catalog from this device. Its favorited channels/movies stay in your shared Favorites list, but will no longer play unless you add this playlist back.':
      "Rimuove da questo dispositivo l'account e il catalogo in cache di «{name}». I suoi canali e film preferiti restano nei Preferiti, ma non si riprodurranno finché non aggiungi di nuovo questa lista.",
  'Delete': "Elimina",
  'Add backup server': "Aggiungi server di riserva",
  'The full address, exactly like the main one — for example http://backup.example.com:8080':
      "L'indirizzo completo, come quello principale; ad esempio http://backup.example.com:8080",
  'Server address': "Indirizzo del server",
  'Add': "Aggiungi",
  'Edit login': "Modifica account",
  'Delete playlist': "Elimina lista",
  'This Playlist': "Questa lista",
  'Playlist enabled': "Lista attiva",
  'Frees up this account\'s stream slot for another device — stops playback here immediately, keeps everything else intact.':
      "Libera la connessione di questo account per un altro dispositivo: ferma subito la riproduzione qui e lascia intatto tutto il resto.",
  'Login Details': "Dati dell'account",
  'Server': "Server",
  'Expires': "Scadenza",
  'Max connections': "Connessioni max.",
  'Backup Servers': "Server di riserva",
  'None yet. If your provider gave you more than one server address for this same account, add them here and this playlist will try them in order whenever the main one can\'t be reached.':
      "Nessuno. Se il provider ti ha dato più indirizzi di server per questo stesso account, aggiungili qui: la lista li proverà in ordine quando quello principale non risponde.",
  'Same username and password as above — only the address differs. Tried in order, a few seconds apart, and whichever answers is used first next time.':
      "Stessi nome utente e password di sopra; cambia solo l'indirizzo. Vengono provati in ordine, a pochi secondi l'uno dall'altro, e quello che risponde viene usato per primo la volta successiva.",
  'Content Overview': "Panoramica contenuti",
  'Not loaded yet.': "Non ancora caricato.",
  '{p} live channels · {p2} movie categories · {p3} TV show categories':
      "{p} canali in diretta · {p2} categorie di film · {p3} categorie di serie",
  '{p} live · {p2} movies · {p3} TV shows':
      "{p} in diretta · {p2} film · {p3} serie",
  'Last updated: {p}': "Ultimo agg.: {p}",
  'Added: {p}': "Aggiunta: {p}",
  'Hidden Channels': "Canali nascosti",
  'Hide a group here and it\'s excluded from the background download too, not just the browse tabs.':
      "Un gruppo nascosto qui viene escluso anche dal download in background, non solo dalle schede.",
  'Full Catalog Sync': "Sincronizzazione completa del catalogo",
  'Update content every': "Aggiorna i contenuti ogni",
  '1 day': "1 giorno",
  '{d} days': "{d} giorni",
  'A stale sync prompts "Update content now?" on launch instead of running automatically.':
      "Una sincronizzazione vecchia mostra «Aggiornare i contenuti adesso?» all'avvio invece di partire da sola.",
  'in use': "in uso",
  'Remove {server}': "Rimuovi {server}",
  'Which playlist\'s groups show first — set independently for each tab below.':
      "Quale lista mostra prima i suoi gruppi; si imposta separatamente per ogni scheda qui sotto.",
  'Add another enabled playlist to set a priority between them.':
      "Aggiungi un'altra lista attiva per impostare una priorità tra le due.",
  'Live TV order': "Ordine TV in diretta",
  'Movies order': "Ordine film",
  'TV Shows order': "Ordine serie",
  'Move up': "Sposta su",
  'Move down': "Sposta giù",
  'Playlist added': "Lista aggiunta",
  'This playlist is disabled on this device — enable it in Settings > Playlist Manager to watch.':
      "Questa lista è disattivata su questo dispositivo: attivala in Impostazioni > Gestione liste per guardare.",

  // ── Profiles / PIN ───────────────────────────────────────────────────
  'Profiles': "Profili",
  'Add Profile': "Aggiungi profilo",
  'Rename profile': "Rinomina profilo",
  'Delete "{name}"?': "Eliminare «{name}»?",
  'Their favorites, hidden groups, and watch history are deleted too. This can\'t be undone.':
      "Vengono eliminati anche preferiti, gruppi nascosti e cronologia. Non si può annullare.",
  'Switch to another profile before deleting this one':
      "Passa a un altro profilo prima di eliminare questo",
  'Delete profile': "Elimina profilo",
  'This is the active profile': "Questo è il profilo attivo",
  'Switch to this profile': "Passa a questo profilo",
  'Rename': "Rinomina",
  'What this profile can see': "Cosa può vedere questo profilo",
  'Groups — {name}': "Gruppi — {name}",
  'Hidden channels — {name}': "Canali nascosti — {name}",
  'For a child — hides every group, including adult content, by default. A parent unhides specific categories per playlist afterward in Group Management. A PIN is required to switch away from this profile or to open Settings while it\'s active.':
      "Per un bambino: nasconde tutti i gruppi per impostazione predefinita, compresi i contenuti per adulti. Poi un genitore mostra categorie specifiche per ogni lista in Gestione gruppi. Serve un PIN per uscire da questo profilo o aprire le Impostazioni mentre è attivo.",
  'Create': "Crea",
  'Incorrect PIN': "PIN errato",
  "PINs didn't match — try again": "I PIN non coincidono: riprova",
  'Enter PIN': "Inserisci il PIN",
  'Confirm PIN': "Conferma il PIN",
  'Set a PIN': "Imposta un PIN",
  'Too many attempts — try again in {p}s':
      "Troppi tentativi: riprova tra {p} s",

  // ── Settings menu ────────────────────────────────────────────────────
  'M3U URL or Xtream Codes login': "URL M3U o account Xtream Codes",
  'Every playlist: login, groups, enable/disable':
      "Tutte le liste: account, gruppi, attiva/disattiva",
  'Separate favorites, history & hidden groups per viewer':
      "Preferiti, cronologia e gruppi nascosti separati per persona",
  'Language and history': "Lingua e cronologia",
  'Language, startup, Multiview and history':
      "Lingua, avvio, Multivista e cronologia",
  'Theme': "Tema",
  'Clock, accent color, layout': "Orologio, colore, layout",
  'Auto-refresh, channel matching & pairing, clear cache':
      "Agg. automatico, abbinamento canali, svuota cache",
  'TMDB (Release Dates)': "TMDB (date di uscita)",
  'Optional key for sorting by real release date':
      "Chiave facoltativa per ordinare per data di uscita reale",
  'Download and install the latest release':
      "Scarica e installa l'ultima versione",
  'Version —': "Versione —",
  'Version {version}': "Versione {version}",
  'Report any bugs or glitches to noxqcx@gmail.com':
      "Segnala bug o problemi a noxqcx@gmail.com",

  // ── Theme ────────────────────────────────────────────────────────────
  'Show clock': "Mostra orologio",
  'Displays the current time in the top bar':
      "Mostra l'ora nella barra in alto",
  'Theme color': "Colore del tema",
  'Auto picks phone vs TV layout by screen size — force one if your box isn\'t detected correctly.':
      "«Auto» sceglie il layout telefono o TV in base allo schermo; forzane uno se il tuo box non viene riconosciuto bene.",
  'Live TV guide': "Guida TV in diretta",
  'Timeline shows every channel at once, on a scrollable schedule grid, instead of one channel\'s now/next at a time.':
      "«Palinsesto» mostra tutti i canali insieme in una griglia scorrevole, invece dell'ora/dopo di un canale alla volta.",
  'Full-screen video behind the guide':
      "Video a schermo intero dietro la guida",
  'The live channel fills the screen behind a see-through guide showing 3 rows':
      "Il canale in diretta riempie lo schermo dietro una guida trasparente a 3 righe",
  'Auto': "Auto",
  'Phone': "Telefono",
  'Timeline': "Palinsesto",
  'Platinum': "Platino",
  'Rosé': "Rosé",
  'Neon Purple': "Viola neon",
  'Neon Green': "Verde neon",
  'Aqua': "Acquamarina",
  'Red': "Rosso",
  'Blue': "Blu",
  'Dark / Gold': "Nero / Oro",

  // ── TMDB ─────────────────────────────────────────────────────────────
  'Cleared — TMDB sorting is now off':
      "Cancellata: l'ordinamento TMDB è disattivato",
  'Saved — key verified with TMDB ✓': "Salvata: chiave verificata con TMDB ✓",
  'Saved, but TMDB rejected this key — double-check it\'s correct':
      "Salvata, ma TMDB ha rifiutato la chiave: controlla che sia giusta",
  'What\'s New refreshed from TMDB': "Novità aggiornate da TMDB",
  'TMDB (The Movie Database) is a free, independent movie and TV database — not your IPTV provider. Adding your own free TMDB key lets VesperTV look up a title\'s actual real-world release date, which powers two things: a "TMDB" sort option on any group\'s "Expand catalog" screen, and a more accurate "What\'s New" row (ordered by real release date instead of just when your provider added the title).':
      "TMDB (The Movie Database) è un database di film e serie gratuito e indipendente, non il tuo provider IPTV. Con una tua chiave TMDB gratuita, VesperTV trova la data di uscita reale di un titolo, utile per due cose: un ordinamento «TMDB» nella schermata «Catalogo completo» di ogni gruppo e una riga «Novità» più precisa (ordinata per data di uscita reale invece che per quando il provider ha aggiunto il titolo).",
  'This is completely optional and free — VesperTV works 100% without it. Without a key, sorting just falls back to whenever your provider added or updated each title, which is still available and works fine on its own.':
      "È del tutto facoltativa e gratuita: VesperTV funziona al 100% anche senza. Senza chiave, l'ordinamento usa la data in cui il provider ha aggiunto o aggiornato ogni titolo, che funziona bene comunque.",
  'To get one: create a free account at themoviedb.org, then generate an API key under Settings > API (choose "Personal use" when asked) and paste it below. VesperTV never collects or shares it — it\'s stored only on this device.':
      "Per ottenerla: crea un account gratuito su themoviedb.org, genera una chiave API in Settings > API (scegli «Personal use» quando richiesto) e incollala qui sotto. VesperTV non la raccoglie né la condivide mai: resta solo su questo dispositivo.",
  'TMDB API Key': "Chiave API TMDB",
  'What\'s New only re-checks TMDB about once a week on its own. Use this to force it right now instead of waiting — useful right after saving a key for the first time.':
      "Novità ricontrolla TMDB da sola circa una volta a settimana. Usa questo per forzarla subito; utile appena salvata una chiave per la prima volta.",
  'Refresh What\'s New Now': "Aggiorna Novità ora",
  'This product uses the TMDB API but is not endorsed or certified by TMDB.':
      "Questo prodotto usa l'API TMDB ma non è approvato né certificato da TMDB.",

  // ── Loading phases / connection ──────────────────────────────────────
  'No Title': "Senza titolo",
  'Reconnecting...': "Riconnessione…",
  'Trying to reconnect on backup servers ({p}/{candidates})...':
      "Tentativo di riconnessione ai server di riserva ({p}/{candidates})…",
  'Finding live channels... ({p} found)':
      "Ricerca canali in diretta… ({p} trovati)",
  'Finding movies... ({p} found)': "Ricerca film… ({p} trovati)",
  'Finding TV shows... ({p} found)': "Ricerca serie… ({p} trovate)",
  'Connecting to {label} ({p}/{candidates})...':
      "Connessione a {label} ({p}/{candidates})…",
  'Connected to {label}': "Connesso a {label}",
  'Connecting to {label} ({p}/{candidates})... failed':
      "Connessione a {label} ({p}/{candidates})… non riuscita",
  'Finding live channels...': "Ricerca canali in diretta…",
  'Finding live channels... ({loadedLive} found)':
      "Ricerca canali in diretta… ({loadedLive} trovati)",
  'Finding movie categories...': "Ricerca categorie di film…",
  'Finding movies... ({vodCategories} categories found)':
      "Ricerca film… ({vodCategories} categorie trovate)",
  'Finding TV show categories...': "Ricerca categorie di serie…",
  'Finding TV shows... ({seriesCategories} categories found)':
      "Ricerca serie… ({seriesCategories} categorie trovate)",
  'Loading full catalog in the background — {p}':
      "Caricamento del catalogo completo in background — {p}",
  'Ready': "Pronto",
  '{done}/{total} categories': "{done}/{total} categorie",

  'Failed to load EPG (HTTP {code})':
      "Impossibile caricare la guida (HTTP {code})",
  'Failed to load playlist from {host} (HTTP {code})':
      "Impossibile caricare la lista da {host} (HTTP {code})",
  'Xtream request to {server} failed: {action} (HTTP {code})':
      "Richiesta Xtream a {server} non riuscita: {action} (HTTP {code})",
  'Main': "Principale",
  '{h}h ': "{h} h ",

  // ── Small widgets ────────────────────────────────────────────────────
  'Unpin': "Rimuovi dai preferiti",
  'Pin as favorite': "Fissa nei preferiti",
  'Next: {p}': "Dopo: {p}",
  'NOW: {title} ({p}-{p2})': "ORA: {title} ({p}-{p2})",
  'NEXT: {title} ({p})': "DOPO: {title} ({p})",
  'Hold ': "Tieni premuto ",
  ' to resume': " per riprendere",
  'Expand sidebar': "Espandi pannello",
  'Collapse sidebar': "Comprimi pannello",
  'Pinned channels': "Canali fissati",
  'League manager': "Gestione campionati",
  'Your leagues': "I tuoi campionati",
  'League bank': "Archivio campionati",
  'Every league is added.': "Tutti i campionati sono aggiunti.",
  'Added · hold to send back': "Aggiunto · tieni premuto per rimetterlo",
  '{name} is back in the league bank':
      "{name} è tornato nell'archivio campionati",
  'England': "Inghilterra",
  'Spain': "Spagna",
  'Germany': "Germania",
  'Italy': "Italia",
  'France': "Francia",
  'Europe': "Europa",
  'Cups': "Coppe",
  'Americas': "Americhe",
  'World': "Mondo",
  'Women': "Femminile",
  'Basketball': "Basket",
  'Hockey': "Hockey",
  'Baseball': "Baseball",
  'Other': "Altri",
  'Golf': "Golf",
  'Tennis': "Tennis",
  'Rugby': "Rugby",
  'Cricket': "Cricket",
  'Darts': "Freccette",
  'Fighting': "Combattimento",
  'Motorsport': "Motori",
  'Always for {name}': "Sempre per {name}",
  'Best for a channel that carries the whole series':
      "Ideale per un canale che trasmette tutta la serie",
  'Next game: {date}': "Prossima partita: {date}",
  'No upcoming games listed yet for this league.':
      "Ancora nessuna partita in programma per questo campionato.",
  'Transfer to another device': "Trasferisci su un altro dispositivo",
  'Copy all of your data to another device':
      "Copia tutti i tuoi dati su un altro dispositivo",
  'Copies your playlists, favorites, hidden groups, profiles, watch progress, {tab} (leagues, favourite league, My Teams) and settings to another device. On the same Wi-Fi it goes straight across; anywhere else it goes through an encrypted upload only the code can open. Channels, movies and the guide download again on the new device.':
      "Copia liste, preferiti, gruppi nascosti, profili, progressi, {tab} (campionati, campionato preferito, Le mie squadre) e impostazioni su un altro dispositivo. Sullo stesso Wi-Fi passa direttamente; altrove passa da un caricamento cifrato che solo il codice può aprire. Canali, film e guida vengono scaricati di nuovo sul nuovo dispositivo.",
  'This setup is too big to upload. Use the same-Wi-Fi transfer instead.':
      "Questa configurazione è troppo grande da caricare. Usa invece il trasferimento sullo stesso Wi-Fi.",
  'Couldn\'t reach the VesperTV transfer server. Check this device\'s internet connection and try again.':
      "Impossibile raggiungere il server di trasferimento VesperTV. Controlla la connessione internet di questo dispositivo e riprova.",
  '{n} hour': "{n} ora",
  '{n} hours': "{n} ore",
  '{n} day': "{n} giorno",
  '{n} days': "{n} giorni",
  'Your setup is encrypted on this device and uploaded. Any device that enters the code can copy it until it expires — even with this device turned off. How long should it stay available?':
      "La configurazione viene cifrata su questo dispositivo e caricata. Qualsiasi dispositivo che inserisce il codice può copiarla fino alla scadenza, anche con questo dispositivo spento. Per quanto tempo deve restare disponibile?",
  'Encrypting and uploading…': "Cifratura e caricamento…",
  'Works on any network until {time}':
      "Funziona su qualsiasi rete fino a: {time}",
  'Anyone with this code can copy your setup, playlist logins included. Changes made after this upload aren\'t in it — upload again to update it.':
      "Chiunque abbia questo codice può copiare la configurazione, credenziali delle liste comprese. Le modifiche fatte dopo questo caricamento non sono incluse: carica di nuovo per aggiornarla.",
  'Upload again': "Carica di nuovo",
  'Delete now': "Elimina ora",
  'Nothing was found for that code. Check it — the upload may also have expired or been deleted.':
      "Non è stato trovato nulla per questo codice. Controllalo: il caricamento potrebbe anche essere scaduto o eliminato.",
  '9 digits on the same Wi-Fi, 16 digits over the internet':
      "9 cifre sullo stesso Wi-Fi, 16 via internet",
  '24-hour clock': "Orologio a 24 ore",
  'Times show as 21:30': "Gli orari appaiono così: 21:30",
  'Times show as 9:30 PM': "Gli orari appaiono così: 9:30 PM",
  'Welcome back, legend': "Bentornato, leggenda",
  'No favourites yet. Hold Select on a poster or a group to add one.':
      "Ancora nessun preferito. Tieni premuto OK su una locandina o un gruppo per aggiungerne uno.",
  'Rotate': "Ruota",
  'You have great taste': "Hai davvero buon gusto",
  'Looking sharp today': "Oggi sei in gran forma",
  'You make this place better': "Rendi questo posto migliore",
  'Hey superstar': "Ciao, superstar",
  'You deserve this break': "Ti meriti questa pausa",
  'You\'re doing amazing': "Stai andando alla grande",
  'Hello, wonderful you': "Ciao, persona meravigliosa",
  'Smart choice, as always': "Ottima scelta, come sempre",
  'You light up the room': "Illumini la stanza",
  'Keep shining, you\'ve got this': "Continua a brillare, ce la fai",
  'You earned some fun today': "Oggi ti sei meritato un po' di svago",
  'The world is better with you in it': "Il mondo è migliore con te",
  'Hey champ, welcome in': "Ciao campione, benvenuto",
  'Send from this device': "Invia da questo dispositivo",
  'Shows a code to enter on the other device':
      "Mostra un codice da inserire sull'altro dispositivo",
  'Both devices on the same Wi-Fi?':
      "Entrambi i dispositivi sullo stesso Wi-Fi?",
  'Send directly, without uploading': "Invia direttamente, senza caricare",
  'Receive on this device': "Ricevi su questo dispositivo",
  'Replaces this device\'s setup with the other one\'s':
      "Sostituisce la configurazione di questo dispositivo con quella dell'altro",
  'This device isn\'t on a Wi-Fi or wired home network.':
      "Questo dispositivo non è su una rete Wi-Fi o via cavo.",
  'Sent! Finish on the other device.':
      "Inviato! Completa sull'altro dispositivo.",
  'This code has expired. Go back and start again.':
      "Questo codice è scaduto. Torna indietro e ricomincia.",
  'On the other device, open Settings > Transfer to another device > Receive, and enter:':
      "Sull'altro dispositivo, apri Impostazioni > Trasferisci su un altro dispositivo > Ricevi e inserisci:",
  'This device: {address} · the code works once, for 10 minutes':
      "Questo dispositivo: {address} · il codice vale una volta, per 10 minuti",
  'Couldn\'t find the other device. Check the code, and that both devices are on the same Wi-Fi with the code still showing.':
      "Impossibile trovare l'altro dispositivo. Controlla il codice e che entrambi siano sullo stesso Wi-Fi con il codice ancora visibile.",
  'That code isn\'t right. Check it on the other device.':
      "Il codice non è corretto. Controllalo sull'altro dispositivo.",
  'That code has expired or was already used. Start again on the other device.':
      "Il codice è scaduto o è già stato usato. Ricomincia sull'altro dispositivo.",
  'The transfer didn\'t go through. Try again.':
      "Il trasferimento non è riuscito. Riprova.",
  'Transfer complete': "Trasferimento completato",
  'VesperTV will close now. Open it again to load your playlists.':
      "VesperTV ora si chiuderà. Riaprilo per caricare le tue liste.",
  'Enter the code shown on the other device':
      "Inserisci il codice mostrato sull'altro dispositivo",
  'Ready to copy': "Pronto da copiare",
  '{playlists} playlists · {profiles} profiles · {favorites} favorites':
      "Liste: {playlists} · Profili: {profiles} · Preferiti: {favorites}",
  'This replaces the playlists, favorites and settings on this device.':
      "Questo sostituisce liste, preferiti e impostazioni di questo dispositivo.",
  'Replace my data': "Sostituisci i miei dati",
  'Enter the address shown under the code on the other device (This device: …)':
      "Inserisci l'indirizzo mostrato sotto il codice sull'altro dispositivo (Questo dispositivo: …)",
  'Code: {code}': "Codice: {code}",
  'Type the address instead': "Inserisci l'indirizzo",
  '{n} playlist': "{n} lista",
  '{n} playlists': "{n} liste",
  '{n} profile': "{n} profilo",
  '{n} profiles': "{n} profili",
  '{n} favorite': "{n} preferito",
  '{n} favorites': "{n} preferiti",
  'Clear favourites?': "Cancellare i preferiti?",
  "Removes every starred item and favourite group from this tab's Favourites.":
      "Rimuove tutti gli elementi con stella e i gruppi preferiti dai Preferiti di questa scheda.",
  'Favourites cleared.': "Preferiti cancellati.",
  'Delete watched history?': "Eliminare la cronologia di visione?",
  'Removes the History list of live channels.':
      "Cancella l'elenco Cronologia dei canali in diretta.",
  'Watched history deleted.': "Cronologia di visione eliminata.",
  'NFL RedZone channel': "Canale NFL RedZone",
  // Series detail screen
  'Resume {code}': "Riprendi {code}",
  'Play {code}': "Riproduci {code}",
  '{n} seasons': "{n} stagioni",
  '{n} episodes': "{n} episodi",
  '1 episode': "1 episodio",
  '{m} min': "{m} min",
  '{h} h {m} min': "{h} h {m} min",
  'Episode {n}': "Episodio {n}",
  'Watched': "Visto",
  'More': "Altro",
  'Watching': "In visione",
  'Marked as watched': "Segnato come visto",
  'Marked as unwatched': "Segnato come non visto",
  'Hold to mark as watched': "Tieni premuto per segnare come visto",
  'Hold to mark as unwatched': "Tieni premuto per segnare come non visto",
  'Cast: {names}': "Cast: {names}",
  'Director: {names}': "Regia: {names}",
  'Specials': "Speciali",
  'Movie and TV artwork and data may come from TMDB (The Movie Database).':
      "Le immagini e i dati di film e serie possono provenire da TMDB (The Movie Database).",
  '{appName} {version} is available': "{appName} {version} è disponibile",
  "What's new:": "Novità:",
  'A new version is ready to install.':
      "Una nuova versione è pronta per l'installazione.",
  'Skip this version': "Salta questa versione",
  'Later': "Più tardi",
  'See all · stats': "Vedi tutto · statistiche",
  'Live games': "Partite in diretta",
  'Click a game for its stats': "Clicca una partita per le sue statistiche",
  'No games are live right now': "Nessuna partita in diretta ora",
  'RED ZONE': "RED ZONE",
  'No channel': "Nessun canale",
  'Watch on {channel}': "Guarda su {channel}",
  'No channel found. Hold OK on the game in {tab} to pick one.':
      "Nessun canale trovato. Tieni premuto OK sulla partita in {tab} per sceglierne uno.",
  '▲▼ scroll · Back closes': "▲▼ scorri · Indietro chiude",
  'Passing': "Passaggi",
  'Rushing': "Corse",
  'Receiving': "Ricezioni",
  'Defense': "Difesa",
  'Kicking': "Calci",
  'Forwards': "Attaccanti",
  'Defensemen': "Difensori",
  'Goalies': "Portieri",
  'Batting': "Battuta",
  'Pitching': "Lanciatori",
  'Players': "Giocatori",
  'No stats for this game yet.':
      "Ancora nessuna statistica per questa partita.",
  'Top performers': "Migliori giocatori",
  'Injuries': "Infortuni",
  'Goals': "Gol",
  'pen.': "rig.",
  'Team stats': "Statistiche di squadra",
  'OK = stats · hold OK = channels · ▶❚❚ = watch':
      "OK = statistiche · tieni premuto OK = canali · ▶❚❚ = guarda",
  '{channel} · full screen': "{channel} · schermo intero",
  // ── Archive tab ──────────────────────────────────────────────────────
  "Add a source": "Aggiungi una fonte",
  "Couldn't load the catalog: {error}":
      "Impossibile caricare il catalogo: {error}",
  "Couldn't reach that link.": "Impossibile raggiungere quel link.",
  "This link failed at the provider. Choose another stream.":
      "Questo link non ha funzionato presso il provider. Scegli un altro stream.",
  "Menu": "Menu",
  "No playable stream for this title.":
      "Nessuno stream riproducibile per questo titolo.",
  "No sources yet.": "Ancora nessuna fonte.",
  "None of your sources has TV shows.": "Nessuna delle tue fonti ha serie TV.",
  "None of your sources has movies.": "Nessuna delle tue fonti ha film.",
  "Nothing here yet.": "Ancora niente qui.",
  "Refresh": "Aggiorna",
  "Source link (ends with manifest.json)":
      "Link della fonte (termina con manifest.json)",
  "That source is already in the list.": "Quella fonte è già nell'elenco.",
  "This source lists no episodes for this show.":
      "Questa fonte non elenca episodi per questa serie.",
  "VesperTV ships no sources. The titles you open are requested from the source you added; nothing else is shared.":
      "VesperTV non include fonti. I titoli che apri vengono richiesti alla fonte che hai aggiunto; nient'altro viene condiviso.",
  "Your sources": "Le tue fonti",
  "{n} TV show catalogs": "{n} cataloghi di serie",
  "{n} movie catalogs": "{n} cataloghi di film",
  "Check the link here, then press Add.":
      "Controlla il link qui, poi premi Aggiungi.",
  "Hide Movies": "Nascondi Film",
  "Hide TV Shows": "Nascondi Serie TV",
  "Hide Recordings": "Nascondi registrazioni",
  "Typing a key with a remote is painful. Scan this code with your phone camera and paste the key there — it appears here for you to check and save.":
      "Digitare una chiave con il telecomando è scomodo. Scansiona questo codice con la fotocamera del telefono e incolla lì la chiave: apparirà qui per controllarla e salvarla.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and save.":
      "Digitare un link lungo con il telecomando è scomodo. Scansiona questo codice con la fotocamera del telefono e incolla lì il link: apparirà qui per controllarlo e salvarlo.",
  "Paste the key and tap Send to TV.":
      "Incolla la chiave e tocca Invia alla TV.",
  "Check it here, then press Save.": "Controlla qui, poi premi Salva.",
  "Paste the link and tap Send to TV.":
      "Incolla il link e tocca Invia alla TV.",
  "Removes the Movies tab and movie search results.":
      "Rimuove la scheda Film e i film dai risultati di ricerca.",
  "Removes the TV Shows tab and show search results.":
      "Rimuove la scheda Serie TV e le serie dai risultati di ricerca.",
  "Removes the Recordings tab.": "Rimuove la scheda Registrazioni.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and add.":
      "Digitare un link lungo con il telecomando è faticoso. Scansiona questo codice con la fotocamera del telefono e incolla lì il link — apparirà qui da controllare e aggiungere.",
  // Archive: rows, search, stream picker
  'Popular': 'Popolari',
  'New': 'Novità',
  'Featured': 'In evidenza',
  'Search movies': 'Cerca film',
  'Search TV shows': 'Cerca serie TV',
  'Title': 'Titolo',
  'Searching…': 'Ricerca…',
  'Clear search': 'Cancella ricerca',
  'Results for "{query}"': 'Risultati per «{query}»',
  'No results for "{query}"': 'Nessun risultato per «{query}»',
  'Choose a stream': 'Scegli un flusso',
  'Stream {n}': 'Flusso {n}',
  // Transfer: Archive tab data
  // Media Hub tab (was Extras, before that Archive) + Multiview toggle
  // Trakt & Simkl (trackers_screen.dart, tracker rows)
  'Watch tracking powered by Trakt and Simkl; VesperTV is not affiliated with or endorsed by either.':
      "Tracciamento della visione fornito da Trakt e Simkl; VesperTV non è affiliato né approvato da nessuno dei due.",
  'Powered by Trakt (trakt.tv) and Simkl (simkl.com).':
      "Basato su Trakt (trakt.tv) e Simkl (simkl.com).",
  'VesperTV is not affiliated with or endorsed by Trakt or Simkl.':
      "VesperTV non è affiliato né approvato da Trakt o Simkl.",
  'Trakt & Simkl': 'Trakt e Simkl',
  'Track what you watch, lists in the Media Hub':
      'Traccia ciò che guardi, liste nel Media Hub',
  'Connected as {name} — press OK to disconnect':
      'Connesso come {name} — premi OK per disconnettere',
  'Not available in this build yet':
      'Non ancora disponibile in questa versione',
  'Connect a watch tracker: what you watch in the Media Hub is marked as watched on your account, and your lists show up as Media Hub rows. Nothing is sent unless you connect an account.':
      'Collega un servizio di tracciamento: ciò che guardi nel Media Hub viene segnato come visto sul tuo account e le tue liste compaiono come righe nel Media Hub. Non viene inviato nulla se non colleghi un account.',
  'Watchlist and trending rows, scrobbling':
      'Righe watchlist e tendenze, scrobbling',
  'Watching and plan-to-watch rows, scrobbling':
      'Righe in visione e da vedere, scrobbling',
  'Titles from your lists play through your stream add-ons (Media Hub sources), by IMDb id. Only titles with an IMDb id are reported.':
      'I titoli delle tue liste vengono riprodotti tramite i tuoi add-on di flussi (fonti Media Hub), per id IMDb. Vengono segnalati solo i titoli con un id IMDb.',
  '{name} connected.': '{name} collegato.',
  'Disconnect {name}?': 'Disconnettere {name}?',
  'Its rows leave the Media Hub and plays are no longer reported. Your account itself is untouched.':
      'Le sue righe escono dal Media Hub e le riproduzioni non vengono più segnalate. Il tuo account non viene modificato.',
  'Disconnect': 'Disconnetti',
  'Couldn\'t reach {name}. Check the connection.':
      'Impossibile raggiungere {name}. Controlla la connessione.',
  'The code expired. Try again.': 'Il codice è scaduto. Riprova.',
  'Sign-in was not completed. Try again.':
      'L\'accesso non è stato completato. Riprova.',
  'Connect {name}': 'Collega {name}',
  'On your phone or computer, open': 'Sul telefono o sul computer, apri',
  'and enter this code:': 'e inserisci questo codice:',
  'Waiting for you to approve…': 'In attesa della tua approvazione…',
  'Try again': 'Riprova',
  'Trakt watchlist': 'Watchlist Trakt',
  'Trending on Trakt': 'Di tendenza su Trakt',
  'Watching on Simkl': 'In visione su Simkl',
  'Simkl plan to watch': 'Da vedere su Simkl',
  // Multiview picker: Live now / Sports shortcuts
  '{n} channels': '{n} canali',
  'No live games on your channels right now':
      'Nessuna partita in diretta sui tuoi canali al momento',
  // Media Hub: Connect Jellyfin / Emby (media_server_screen.dart)
  'Connect Jellyfin / Emby': 'Collega Jellyfin / Emby',
  'User name': 'Nome utente',
  'Connect': 'Collega',
  'Enter the server address and your user name.':
      'Inserisci l\'indirizzo del server e il tuo nome utente.',
  'Wrong user name or password.': 'Nome utente o password errati.',
  'This account has no movie or TV library.':
      'Questo account non ha librerie di film o serie.',
  'Couldn\'t find a Jellyfin or Emby server at that address.':
      'Nessun server Jellyfin o Emby trovato a questo indirizzo.',
  'Sign in to your own Jellyfin or Emby server: its movie and TV libraries show up in the Media Hub. Files play as they are stored on the server (no transcoding).':
      'Accedi al tuo server Jellyfin o Emby: le sue librerie di film e serie compaiono nel Media Hub. I file vengono riprodotti così come sono salvati sul server (senza transcodifica).',
  'Your password is only sent to your server. VesperTV keeps the sign-in token the server gives back, not the password.':
      'La password viene inviata solo al tuo server. VesperTV conserva il token di accesso restituito dal server, non la password.',
  'Media Hub': 'Media Hub',
  'Media Hub sources': 'Fonti Media Hub',
  'Add-on sources for the Media Hub tab':
      'Fonti add-on per la scheda Media Hub',
  'Clear Media Hub?': 'Cancellare il Media Hub?',
  'Clear Media Hub': 'Cancella Media Hub',
  'Media Hub cleared.': 'Media Hub cancellato.',
  'Include Media Hub tab data': 'Includi i dati della scheda Media Hub',
  'Media Hub sources and their watch progress are sent too':
      'Vengono inviati anche le fonti Media Hub e i progressi di visione',
  'The other device keeps its own Media Hub sources':
      'L\'altro dispositivo mantiene le proprie fonti Media Hub',
  'Add a source to browse films and series. Any source that follows the catalog/stream add-on format works.':
      'Aggiungi una fonte per sfogliare film e serie. Funziona qualsiasi fonte che segua il formato add-on catalogo/flusso.',
  'That link isn\'t a Media Hub source (it needs movie or series streams).':
      'Quel link non è una fonte Media Hub (servono flussi di film o serie).',
  'Removes every Media Hub source and its saved catalog from this device.':
      'Rimuove tutte le fonti Media Hub e il loro catalogo salvato da questo dispositivo.',
  'The Media Hub tab shows films and series from sources you add here. Any source that follows the catalog/stream add-on format works; a source that only offers streams by IMDb id gets its posters and episodes from Cinemeta. Only direct video links are played; torrent links are ignored.':
      'La scheda Media Hub mostra film e serie dalle fonti che aggiungi qui. Funziona qualsiasi fonte che segua il formato add-on catalogo/flusso; una fonte che offre solo flussi per id IMDb prende locandine ed episodi da Cinemeta. Si riproducono solo link video diretti; i link torrent vengono ignorati.',
  'Hide Media Hub': 'Nascondi Media Hub',
  'Removes the Media Hub tab.': 'Rimuove la scheda Media Hub.',
  'Hide Multiview': 'Nascondi Multivista',
  'Removes the Multiview row and the player\'s Open in Multiview button.':
      'Rimuove la riga Multivista e il pulsante Apri in Multivista del lettore.',
  // Extras genre filter
  'Genre': 'Genere',
  'All genres': 'Tutti i generi',
  'genre.Action': 'Azione',
  'genre.Adventure': 'Avventura',
  'genre.Animation': 'Animazione',
  'genre.Biography': 'Biografico',
  'genre.Comedy': 'Commedia',
  'genre.Crime': 'Crimine',
  'genre.Documentary': 'Documentario',
  'genre.Drama': 'Drammatico',
  'genre.Family': 'Famiglia',
  'genre.Fantasy': 'Fantasy',
  'genre.History': 'Storico',
  'genre.Horror': 'Horror',
  'genre.Mystery': 'Mistero',
  'genre.Romance': 'Sentimentale',
  'genre.Sci-Fi': 'Fantascienza',
  'genre.Sport': 'Sport',
  'genre.Thriller': 'Thriller',
  'genre.War': 'Guerra',
  'genre.Western': 'Western',
  'genre.Reality-TV': 'Reality',
  'genre.Talk-Show': 'Talk show',
  'genre.Game-Show': 'Quiz',
  // Sports: favourite league
  'OK: show/hide or add · Hold OK: favourite league, or send an added league back to the bank':
      'OK: mostra/nascondi o aggiungi · Tieni premuto OK: campionato preferito, o rimetti nell\'archivio un campionato aggiunto',
  'Make favourite league': 'Rendi campionato preferito',
  'Remove from favourite': 'Togli dai preferiti',
  '{tab} opens on it and its games come first in Live now':
      '{tab} si apre su di esso e le sue partite vengono prima in In diretta',
  'Send back to the league bank': 'Rimetti nell\'archivio dei campionati',
  'Favourite league': 'Campionato preferito',
  // Player side panel: Pull stats
  '◀ ▶ tabs  ·  OK to watch  ·  Hold OK for stats  ·  Back to close':
      '◀ ▶ schede  ·  OK per guardare  ·  Tieni premuto OK: statistiche  ·  Indietro per chiudere',
  // Sports hero on Windows
  'Click the game again or Enter: full screen  ·  Esc: stop':
      'Clicca di nuovo la partita o Invio: schermo intero  ·  Esc: ferma',
  'Click again: watch here  ·  Hold: pick the channel':
      'Clicca di nuovo: guarda qui  ·  Tieni premuto: scegli il canale',
  // Extras floating Search / Genre bar
  'Movie genres': 'Generi di film',
  'TV show genres': 'Generi di serie',
  // Extras: watched history + recent searches
  'Recently watched': 'Visti di recente',
  'Clear recent searches': 'Cancella ricerche recenti',
  // Data pool (player stream details, Settings > General)
  "Data pool": "Data pool",
  "Data pool display": "Mostra il Data pool",
  "Press OK while a live channel plays to open a second card under the channel info with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Premi OK mentre è in onda un canale live per aprire una seconda scheda sotto le info del canale con i dettagli dello stream: risoluzione, fotogrammi al secondo, codec, bitrate, varianti di qualità, tracce audio, buffer e HDR. Disattivato: OK mostra solo le info del canale.",
  "Reading the stream…": "Lettura dello stream…",
  "Video": "Video",
  "Video bitrate": "Bitrate video",
  "Picture": "Immagine",
  "Quality variants": "Varianti di qualità",
  "One (not adaptive)": "Una (non adattivo)",
  "Audio": "Audio",
  "Audio tracks": "Tracce audio",
  "Stream": "Stream",
  "Buffered": "Nel buffer",
  "{seconds} s": "{seconds} s",
  "State": "Stato",
  "Buffering…": "Buffering…",
  "Playing for {time}": "In riproduzione da {time}",
  "Paused": "In pausa",
  "Device HDR": "HDR del dispositivo",
  "Not reported by the stream": "Non indicato dallo stream",
  "Mono": "Mono",
  "Stereo": "Stereo",
  "Direct stream": "Stream diretto",
  "Yes": "Sì",
  "No": "No",
  "Stream bitrate": "Bitrate dello stream",
  "Declared bitrate": "Bitrate dichiarato",
  "Dropped frames": "Fotogrammi persi",
  "(measured)": "(misurato)",
  "Measuring…": "Misurazione…",
  // Settings categories (left panel)
  "Playlists & guide": "Liste e guida",
  "Your playlists and their logins, the TV guide (EPG) and the viewer profiles.":
      "Le tue liste e i loro accessi, la guida TV (EPG) e i profili.",
  "Everything the Media Hub uses: its add-on sources, online subtitles, Trakt & Simkl watch tracking and the optional TMDB key.":
      "Tutto ciò che usa il Media Hub: le fonti add-on, i sottotitoli online, il monitoraggio Trakt e Simkl e la chiave TMDB facoltativa.",
  "Interface": "Interfaccia",
  "How the app looks and what it shows: theme, tabs, matching the TV's frame rate, the player's extras and reminders.":
      "Aspetto dell’app e cosa mostra: tema, schede, frequenza dei fotogrammi del televisore, extra del lettore e promemoria.",
  "Hide Movies, TV Shows, Media Hub, Recordings or Multiview":
      "Nascondi Film, Serie TV, Media Hub, Registrazioni o Multiview",
  "Fixes for the picture on some Fire TV sticks":
      "Correzioni per l’immagine su alcune chiavette Fire TV",
  "Dolby Atmos to your soundbar or receiver":
      "Dolby Atmos alla tua soundbar o al ricevitore",
  "Surround passthrough (Dolby Atmos)": "Audio surround diretto (Dolby Atmos)",
  "Sends Dolby Digital, Dolby Atmos and DTS sound to your soundbar or receiver untouched (HDMI passthrough), so it can play Atmos. Off: this device turns that sound into plain stereo/5.1 first, so Atmos is lost. While on, the volume of that sound is set on your TV or receiver only, and if you hear nothing on a channel, turn this off. Multiview always uses plain sound (passthrough there kept muted screens playing). Applies from the next channel.":
      "Invia l'audio Dolby Digital, Dolby Atmos e DTS così com'è alla soundbar o al ricevitore (passthrough HDMI), così può riprodurre l'Atmos. Disattivato: questo dispositivo converte prima quell'audio in stereo/5.1 normale e l'Atmos si perde. Attivato, il volume di quell'audio si regola solo sulla TV o sul ricevitore, e se su un canale non senti nulla, disattivalo. Il Multiview usa sempre l'audio normale (lì il passthrough lasciava suonare gli schermi silenziati). Vale dal canale successivo.",
  "Stream details when you press OK on a channel":
      "Dettagli del flusso quando premi OK su un canale",
  "One list for every playlist, or one per playlist":
      "Un elenco per tutte le liste, o uno per lista",
  "The connections tip when opening Multiview":
      "Il suggerimento sulle connessioni all’apertura di Multiview",
  "The \"Hold > to resume\" pill":
      "La pillola «Tieni premuto > per riprendere»",
  "Language and clock, what plays when the app starts, Fast startup, and clearing your history.":
      "Lingua e orologio, cosa parte all’avvio, Avvio rapido e la cancellazione della cronologia.",
  "App language and 24-hour clock": "Lingua dell’app e orologio 24 ore",
  "Resume the last channel, Fast startup":
      "Riprendi l’ultimo canale, Avvio rapido",
  "Clear searches, channels, Continue Watching":
      "Cancella ricerche, canali, Continua a guardare",
  "Device & data": "Dispositivo e dati",
  "Move your whole setup to another device, keep a backup of it, and update VesperTV.":
      "Copia l’intera configurazione su un altro dispositivo, conservane un backup e aggiorna VesperTV.",
  // Own live groups (Move to group)
  "Move to group…": "Sposta in un gruppo…",
  "Move {name} to": "Sposta {name} in",
  "New group…": "Nuovo gruppo…",
  "Back to {group}": "Torna in {group}",
  "New group": "Nuovo gruppo",
  "Group name": "Nome del gruppo",
  "{name} is now in {group}": "{name} ora è in {group}",
  "Delete this group": "Elimina questo gruppo",
  "{group} deleted. Its channels are back in their groups.":
      "{group} eliminato. I suoi canali tornano nei loro gruppi.",
  // Fast startup
  "Fast startup": "Avvio rapido",
  "Opens the app without waiting for Movies and TV Shows to load; they fill in a few seconds later. For fast devices — leave it off on an older box if the app closes by itself right after starting. Applies from the next start.":
      "Apre l’app senza aspettare il caricamento di Film e Serie TV; si completano qualche secondo dopo. Per dispositivi veloci — lascialo disattivato su un box più vecchio se l’app si chiude da sola subito dopo l’avvio. Vale dal prossimo avvio.",
  // Group hold menu: New group
  "{group} created. Hold OK on a channel > Move to group… to add channels.":
      "{group} creato. Tieni premuto OK su un canale > Sposta in un gruppo… per aggiungere canali.",
  // Channel menu: Remove from group
  "Remove from {group}": "Rimuovi da {group}",
  // Settings > Device & data > Send log
  "Send log": "Invia log",
  "Send the app's log to the developer":
      "Invia il log dell'app allo sviluppatore",
  "Sending...": "Invio...",
  "Send again": "Invia di nuovo",
  "Log sent. Your code:": "Log inviato. Il tuo codice:",
  "Mention this code on Reddit or Discord with what happened, so the developer can find your log.":
      "Indica questo codice su Reddit o Discord insieme a cosa è successo, così lo sviluppatore trova il tuo log.",
  "Something not working? Send the app's log to the VesperTV developer. It holds what the app did recently (this session and the last one) and your device model, nothing else.":
      "Qualcosa non funziona? Invia il log dell'app allo sviluppatore di VesperTV. Contiene ciò che l'app ha fatto di recente (questa sessione e la precedente) e il modello del dispositivo, nient'altro.",
  "Server addresses, user names, passwords and other private details are removed before sending.":
      "Indirizzi dei server, nomi utente, password e altri dati privati vengono rimossi prima dell'invio.",
  "Too many logs sent from here. Try again in an hour.":
      "Troppi log inviati da qui. Riprova tra un'ora.",
  "Couldn't send the log. Check the internet connection and try again.":
      "Impossibile inviare il log. Controlla la connessione a Internet e riprova.",
  // Recordings (Sports Trak recording, Recordings tab)
  "Watch live": "Guarda in diretta",
  "Play from the start": "Riproduci dall'inizio",
  "What has been recorded so far": "Quanto registrato finora",
  "Stop recording": "Interrompi la registrazione",
  "Keeps what has been recorded": "Conserva quanto registrato",
  "Cancel recording": "Annulla la registrazione",
  "Delete recording": "Elimina la registrazione",
  "Frees {size}": "Libera {size}",
  "Removes it from the list": "La rimuove dall'elenco",
  "Recordings": "Registrazioni",
  "Recording every {team} game": "Registra ogni partita di {team}",
  "Nothing recorded yet. Hold OK on a game in {tab} and pick Record, or hold OK on a live channel.":
      "Ancora nessuna registrazione. Tieni premuto OK su una partita in {tab} e scegli Registra, oppure tieni premuto OK su un canale in diretta.",
  "Recording now": "In registrazione",
  "Recorded": "Registrati",
  "{used} of {cap} GB used": "{used} usati su {cap} GB",
  "REC · {size}": "REG · {size}",
  "Waiting for a channel": "In attesa di un canale",
  "Interrupted · {size}": "Interrotta · {size}",
  "Missed": "Persa",
  "Failed": "Non riuscita",
  "Live channel": "Canale in diretta",
  "Start early: {min} min": "Inizia prima: {min} min",
  "Before the game's scheduled start":
      "Prima dell'inizio previsto della partita",
  "Keep recording: {min} min": "Continua a registrare: {min} min",
  "After the scheduled end, for overtime and delays":
      "Dopo la fine prevista, per supplementari e ritardi",
  "Space for recordings: {gb} GB": "Spazio per le registrazioni: {gb} GB",
  "{used} used. Recording stops when this is full or the storage has less than 1 GB left.":
      "{used} usati. La registrazione si ferma quando lo spazio è pieno o resta meno di 1 GB.",
  "Save recordings to": "Salva le registrazioni in",
  "USB drive / SD card": "Chiavetta USB / scheda SD",
  "This device": "Questo dispositivo",
  "{free} free of {total}": "{free} liberi su {total}",
  "Plug in a USB drive or SD card to record to it. Recordings on this device are deleted if VesperTV is uninstalled.":
      "Collega una chiavetta USB o una scheda SD per registrare lì. Le registrazioni su questo dispositivo vengono eliminate se VesperTV viene disinstallato.",
  "Recording in progress": "Registrazione in corso",
  "{title} is recording on {channel}. Your playlist allows one connection, so playing another of its channels stops the recording.":
      "{title} è in registrazione su {channel}. La tua playlist consente una connessione, quindi guardare un altro dei suoi canali interrompe la registrazione.",
  "Recording cancelled": "Registrazione annullata",
  "Not enough free space to record": "Spazio insufficiente per registrare",
  "Recording {title}": "Registrazione di {title}",
  "{title} will be recorded": "{title} verrà registrata",
  "No longer recording every {team} game":
      "Le partite di {team} non vengono più registrate",
  "Every {team} game will be recorded":
      "Ogni partita di {team} verrà registrata",
  "Waiting for a channel in the guide": "In attesa di un canale nella guida",
  "Record": "Registra",
  "{channel} · starts now": "{channel} · inizia ora",
  "{channel} · from {time}": "{channel} · dalle {time}",
  "Stop recording every {team} game":
      "Smetti di registrare ogni partita di {team}",
  "Record every {team} game": "Registra ogni partita di {team}",
  "Recordings already made are kept": "Le registrazioni già fatte restano",
  "One team at a time, on the channel {tab} picks":
      "Una squadra alla volta, sul canale scelto da {tab}",
  "Replaces {team}": "Sostituisce {team}",
  "Recording stopped": "Registrazione interrotta",
  "Margins, space and where recordings are saved":
      "Margini, spazio e dove si salvano",
  "Record until the show ends": "Registra fino alla fine del programma",
  "Record until I stop it": "Registra finché non la interrompo",
  "Keeps going across shows (4 hours at most)":
      "Continua tra un programma e l'altro (massimo 4 ore)",
  "{title} · stops at {time}": "{title} · si ferma alle {time}",
  "No guide for this channel: stops after 2 hours":
      "Nessuna guida per questo canale: si ferma dopo 2 ore",
  // Media Hub: Ready tag / Debrid accounts
  "Cleared": "Cancellato",
  "Saved — key verified ✓": "Salvato — chiave verificata ✓",
  "Saved, but {service} rejected the key — double-check it":
      "Salvato, ma {service} ha rifiutato la chiave — controllala",
  "Debrid accounts": "Account debrid",
  "Optional keys for the \"Ready\" tag":
      "Chiavi facoltative per l'etichetta «Pronto»",
  "Some Media Hub sources answer Play with a short \"being downloaded\" video while they fetch a title into your debrid account. VesperTV then checks back every minute and puts a \"Ready\" tag on the title's poster once it's there.":
      "Alcune sorgenti del Media Hub rispondono a Riproduci con un breve video «in download» mentre portano un titolo nel tuo account debrid. VesperTV ricontrolla ogni minuto e mette un'etichetta «Pronto» sulla locandina del titolo appena è disponibile.",
  "Optional: with your own key, your account confirms it directly. Without one, VesperTV asks the source again until the full file answers.":
      "Facoltativo: con la tua chiave, è il tuo account a confermarlo direttamente. Senza, VesperTV richiede alla sorgente finché non risponde il file completo.",
  "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (API key). Kept in VesperTV and only used to read your downloads list.":
      "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (chiave API). Conservata in VesperTV e usata solo per leggere l'elenco dei tuoi download.",
  "Real-Debrid API token": "Token API Real-Debrid",
  "TorBox API key": "Chiave API TorBox",
  // Sports Trak: League bank heading for college conferences
  "College": "Universitario",
  // Settings > General > Support VesperTV
  "Support VesperTV": "Sostieni VesperTV",
  "Buy a coffee or become a Supporter": "Offri un caffè o diventa Supporter",
  "VesperTV is free and always will be: no ads, no tracking, no paid features. If you enjoy it, you can buy a coffee or become a Supporter to help pay for the server, the website and development.":
      "VesperTV è gratuito e lo sarà sempre: niente pubblicità, niente tracciamento, nessuna funzione a pagamento. Se ti piace, puoi offrire un caffè o diventare Supporter per aiutare a pagare il server, il sito e lo sviluppo.",
  "Supporting is a thank-you, never a paywall: everyone gets the same app.":
      "Sostenere è un grazie, mai un accesso a pagamento: tutti hanno la stessa app.",
  // Settings > General > Remote tips
  "Language and clock, what plays when the app starts, Fast startup, clearing your history, and remote tips.":
      "Lingua e orologio, cosa parte all'avvio, Avvio rapido, cancellare la cronologia e i trucchi del telecomando.",
  "Remote tips": "Trucchi telecomando",
  "Every hold menu and shortcut, on your phone":
      "Ogni menu a pressione lunga e scorciatoia, sul tuo telefono",
  "Every hold menu and remote shortcut, on one page: hold OK on channels, groups and posters, the side panel on ← in full screen, Multiview, Sports Trak and more.":
      "Ogni menu a pressione lunga e scorciatoia del telecomando in una sola pagina: tenere premuto OK su canali, gruppi e locandine, il pannello laterale con ← a schermo intero, Multiview, Sports Trak e altro.",
  "Scan with your phone, or open": "Inquadra con il telefono, oppure apri",
  "Open": "Apri",
  "The basics: hold OK (about half a second) opens a menu almost everywhere. Back always steps out one level. OK twice on a channel = full screen.":
      "Le basi: tenere premuto OK (circa mezzo secondo) apre un menu quasi ovunque. Indietro esce sempre di un livello. OK due volte su un canale = schermo intero.",
  "Fetching…": "Recupero…",
  // Media Hub: list-only sources
  "Plays through your other sources": "Si riproduce con le tue altre sorgenti",
  // Search: Media Hub results
  "Search Live TV, Movies, TV Shows & the Media Hub":
      "Cerca TV in diretta, film, serie TV e il Media Hub",
  // Player: what an unreadable link really served
  "This file's format can't be played here. Try another stream (an MKV or MP4 one).":
      "Il formato di questo file non può essere riprodotto qui. Prova un altro flusso (MKV o MP4).",
  "Your source sent a message instead of the video:":
      "La tua sorgente ha inviato un messaggio invece del video:",
  "Check your source or debrid account (plan limits, active downloads), or pick another stream.":
      "Controlla la sorgente o l'account debrid (limiti del piano, download attivi) oppure scegli un altro flusso.",
  // Media Hub: import add-ons (pasted links, Stremio)
  "Added to the Media Hub: {names}": "Aggiunto al Media Hub: {names}",
  "Added to subtitle add-ons: {names}":
      "Aggiunto agli add-on dei sottotitoli: {names}",
  "Already added: {names}": "Già aggiunto: {names}",
  "Not usable in VesperTV: {names}": "Non utilizzabile in VesperTV: {names}",
  "Couldn't reach: {names}": "Non raggiungibile: {names}",
  "Import from Stremio": "Importa da Stremio",
  "Couldn't reach Stremio. Check your internet connection.":
      "Impossibile raggiungere Stremio. Controlla la connessione a Internet.",
  "Couldn't read your Stremio add-ons. Try again.":
      "Impossibile leggere i tuoi add-on di Stremio. Riprova.",
  "Copy the add-ons from your Stremio account. Nothing is changed on your Stremio account.":
      "Copia gli add-on dal tuo account Stremio. Sul tuo account Stremio non cambia nulla.",
  "On your phone, scan the code or open":
      "Sul telefono, inquadra il codice o apri",
  "Code": "Codice",
  "Then sign in to Stremio there. This page continues on its own.":
      "Poi accedi a Stremio da lì. Questa pagina prosegue da sola.",
  "Your Stremio account has no add-ons VesperTV can copy.":
      "Il tuo account Stremio non ha add-on che VesperTV possa copiare.",
  "Your Stremio add-ons. Untick any you don't want.":
      "I tuoi add-on di Stremio. Togli la spunta a quelli che non vuoi.",
  "Add {n} add-ons": "Aggiungi {n} add-on",
  "Already added": "Già aggiunto",
  "Can't play in VesperTV": "Non riproducibile in VesperTV",
  "Several links at once work too.": "Funzionano anche più link insieme.",
  "{n} links checked": "{n} link controllati",
  // Data pool on movies / episodes
  "Press OK while a channel, movie or episode plays to open a card with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Premi OK durante la riproduzione di un canale, un film o un episodio per aprire una scheda con i dettagli del flusso: risoluzione, fotogrammi al secondo, codec, bitrate, varianti di qualità, tracce audio, buffer e HDR. Disattivato: OK mostra solo le info del canale.",
  "Stream details when you press OK while watching":
      "Dettagli del flusso premendo OK durante la visione",
  // CFL official feed
  'East Division': 'Divisione Est',
  'West Division': 'Divisione Ovest',
  'Score unavailable': 'Punteggio non disponibile',
  'Passing yards': 'Yard su passaggio',
  'Rushing yards': 'Yard su corsa',
  'Net offence': 'Attacco netto',
  'First downs': 'Primi down',
  'Sacks': 'Sack',
  '2nd down conversions': 'Conversioni al 2° down',
  'Turnovers': 'Palle perse',
  'Penalties (yards)': 'Penalità (yard)',
  'Field goals': 'Field goal',
  'Time of possession': 'Tempo di possesso',
  'Punting': 'Punt',
  'Kickoffs': 'Kickoff',
  'Kickoff returns': 'Ritorni di kickoff',
  'Punt returns': 'Ritorni di punt',

  "Pick channels myself": "Scegli i miei canali",
  "All groups": "Tutti i gruppi",
  "{count} selected": "{count} selezionati",
  "Select results": "Seleziona risultati",
  "Clear results": "Deseleziona risultati",
  "Browse all channels": "Sfoglia tutti i canali",
  "My sports channels": "I miei canali sportivi",
  "List name": "Nome elenco",
  "Add to list": "Aggiungi a elenco",
  "Create list": "Crea elenco",
  "Edit list": "Modifica elenco",
  "Versions": "Versioni",
  "My lists": "I miei elenchi",
  "League networks": "Canali delle leghe",
  "Sports networks": "Canali sportivi",
  "Regional channels": "Canali regionali",
  "Channels": "Canali",
  "Games": "Partite",
  "Use a playlist group": "Usa un gruppo della playlist",
  "Rename list": "Rinomina elenco",
  "Delete list": "Elimina elenco",

  "Filters": "Filtri",
  "Edit tags": "Modifica etichette",
  "Country": "Paese",
  "Network": "Rete",
  "Sport": "Sport",
  "League": "Lega",
  "Group": "Gruppo",
  "Unknown": "Sconosciuto",
  "Clear all": "Cancella tutto",
  "Keep this list updated": "Mantieni aggiornato questo elenco",
  "Comma-separated tags": "Etichette separate da virgole",
  "Add sources": "Aggiungi fonti",
  "More sources": "Altre fonti",
  "Your added source": "Fonte aggiunta da te",
  "This game": "Questa partita",
  "hockey": "Hockey",
  "basketball": "Pallacanestro",
  "football": "Football americano",
  "soccer": "Calcio",
  "baseball": "Baseball",
  "tennis": "Tennis",
  "golf": "Golf",
  "racing": "Automobilismo",

  "Trailer": "Trailer",
  "Cast": "Cast",
  "Unable to open trailer": "Impossibile aprire il trailer",
  "Next episode airs {date}": "Il prossimo episodio va in onda il {date}",
  "Next episode: {code} · {date}": "Prossimo episodio: {code} · {date}",
  "YouTube playback needs Android System WebView or Microsoft Edge WebView2.":
      "La riproduzione di YouTube richiede Android System WebView o Microsoft Edge WebView2.",
  "YouTube could not play this video ({code}).":
      "YouTube non può riprodurre questo video ({code}).",
  "Open in YouTube": "Apri in YouTube",
  "Back 10 seconds": "Indietro di 10 secondi",
  "Forward 10 seconds": "Avanti di 10 secondi",
  "Play / pause": "Riproduci / pausa",
  "Mark season watched": "Segna stagione come vista",
  "Mark season unwatched": "Segna stagione come non vista",
  "Season {season} marked as watched": "Stagione {season} segnata come vista",
  "Season {season} marked as unwatched":
      "Stagione {season} segnata come non vista",
  "Colour": "Colore",
  "Kids profile": "Profilo bambini",
  "Photo": "Foto",
  "Profile": "Profilo",
  "Actions": "Azioni",
  "Active": "Attivo",
  "Kids & PIN": "Bambini e PIN",
  "Scan with your phone to add a photo":
      "Scansiona con il telefono per aggiungere una foto",
  "Choose a photo": "Scegli una foto",
  "Remove photo": "Rimuovi foto",
  "Choose a photo and tap Send to TV.":
      "Scegli una foto e tocca Invia alla TV.",
  "Your photo appears here automatically.":
      "La foto appare qui automaticamente.",
  "Could not read photo. Choose a JPEG or PNG under 2 MB.":
      "Impossibile leggere la foto. Scegli un JPEG o PNG inferiore a 2 MB.",
  "Could not save profile. Try again.":
      "Impossibile salvare il profilo. Riprova.",
  "Watch history": "Cronologia di visione",
  "Hidden groups and channels": "Gruppi e canali nascosti",
  "Home rows layout": "Disposizione righe Home",
  "What should this profile get from Main?":
      "Cosa deve ricevere questo profilo da Principale?",
  "Copies are independent. Playlists, accounts and device settings stay shared.":
      "Le copie sono indipendenti. Playlist, account e impostazioni del dispositivo restano condivisi.",
  "Everything": "Tutto",
  "None": "Nessuno",
  "Save name": "Salva nome",
  "Saving…": "Salvataggio…",
  "Profile restrictions are fixed when the profile is created.":
      "Le restrizioni vengono fissate alla creazione del profilo.",
  "{n} groups allowed": "{n} gruppi consentiti",
  "{groups} groups hidden · {channels} channels hidden":
      "{groups} gruppi nascosti · {channels} canali nascosti",
  "Main cannot be deleted": "Impossibile eliminare Principale",
  "Hold OK on a profile to edit it. Hold OK on a season to mark it watched or unwatched.":
      "Tieni premuto OK su un profilo per modificarlo o su una stagione per segnarla vista o non vista.",
  'Coming soon': 'Prossimamente',
  "Show Cinemeta catalog": "Mostra il catalogo Cinemeta",
  "Show the default Popular, New and Featured rows and Cinemeta search results. Turn off to browse only your own catalogs. Posters and episode details may still use Cinemeta.":
      "Mostra le righe predefinite Popolari, Novità e In evidenza e i risultati di ricerca di Cinemeta. Disattiva per sfogliare solo i tuoi cataloghi. Le locandine e i dettagli degli episodi potrebbero ancora usare Cinemeta.",
  "Expand": "Espandi",
  "Fill the screen with the Timeline guide":
      "Riempi lo schermo con la guida dei programmi",
  "The live channel fills the screen behind a see-through guide":
      "Il canale in diretta riempie lo schermo dietro una guida semitrasparente",
  "Source: {source}": "Fonte: {source}",
  "File size: {size}": "Dimensione del file: {size}",
  "File size unavailable": "Dimensione del file non disponibile",

  // Automatic detail trailers.
  "Automatic trailers": "Trailer automatici",
  "Play available trailers automatically with sound on IPTV and Media Hub movie and show pages.":
      "Riproduci automaticamente con audio i trailer disponibili nelle pagine di film e serie IPTV e Media Hub.",
  "Trailers": "Trailer",
  "Play trailers automatically on movie and show pages":
      "Riproduzione automatica dei trailer nelle pagine di film e serie",
  "On Fire TV sticks, the trailer plays full screen.":
      "Sui Fire TV Stick il trailer viene riprodotto a schermo intero.",
  "Remove \"{title}\" from history?": "Rimuovere \"{title}\" dalla cronologia?",
  "Import from storage": "Importa da memoria esterna",
  "Add M3U playlists and Media Hub sources from USB or external storage":
      "Aggiungi playlist M3U e fonti Media Hub da USB o memoria esterna",
  "Choose a folder": "Scegli una cartella",
  "Import from storage?": "Importare dalla memoria esterna?",
  "Import": "Importa",
  "Import \"{name}\"? M3U playlists and included Media Hub sources are added without replacing your current setup.":
      "Importare \"{name}\"? Le playlist M3U e le fonti Media Hub incluse vengono aggiunte senza sostituire la configurazione attuale.",
  "Import M3U playlists and Media Hub source links from USB, SD card or external storage. Choose M3U/M3U8 playlists or TXT/JSON source files.":
      "Importa playlist M3U e collegamenti a fonti Media Hub da USB, scheda SD o memoria esterna. Scegli playlist M3U/M3U8 o file di fonti TXT/JSON.",
  "Could not read this storage location. Use Choose a folder to grant access.":
      "Impossibile leggere questa posizione. Usa Scegli una cartella per concedere accesso.",
  "No folder picker on this device. Browse the storage devices below instead.":
      "Questo dispositivo non ha un selettore di cartelle. Sfoglia le memorie elencate sotto.",
  "No playlists or source files in this folder.":
      "Nessuna playlist o file di fonti in questa cartella.",
  "Imported {items} playlist items and {sources} Media Hub sources. {existing} sources already existed; {failed} could not be reached.":
      "Importati {items} elementi delle playlist e {sources} fonti Media Hub. {existing} fonti erano già presenti; {failed} non erano raggiungibili.",
  "Could not import this file. Choose an M3U channel playlist or a TXT/JSON file containing Media Hub manifest links.":
      "Impossibile importare questo file. Scegli una lista di canali M3U o un file TXT/JSON con collegamenti ai manifest di Media Hub.",
  "Hide profiles": "Nascondi profili",
  "Hides the profiles row on Home.": "Nasconde la riga dei profili nella Home.",
  "Preferred audio language": "Lingua audio preferita",
  "Preferred subtitle language": "Lingua dei sottotitoli preferita",
  "Source default": "Predefinita della sorgente",
  "Movies and episodes use these languages when available. Your manual track choices take priority when resuming.":
      "Film ed episodi usano queste lingue quando disponibili. Le tracce scelte manualmente hanno la priorità alla ripresa.",
  "Playback": "Riproduzione",
  "Frame rate & resolution": "Frequenza fotogrammi e risoluzione",
  "Video, audio, subtitles, trailers and player behaviour.":
      "Video, audio, sottotitoli, trailer e comportamento del lettore.",
  "Theme, tabs, favourites and how the app looks.":
      "Tema, schede, preferiti e aspetto dell’app.",
  "Audio languages, subtitles and surround sound":
      "Lingue audio, sottotitoli e audio surround",
  "Media Hub playback": "Riproduzione Media Hub",
  "Default stream selection for movies and episodes":
      "Selezione predefinita del flusso per film ed episodi",
  "Boxing": "Pugilato",
  "Stream sources": "Sorgenti dello streaming",
  "Up/Down: browse · OK: switch · Back: close":
      "Su/Giù: sfoglia · OK: cambia · Indietro: chiudi",
  "Could not load stream sources.":
      "Impossibile caricare le sorgenti dello streaming.",
  "Could not switch stream. Try another source.":
      "Impossibile cambiare streaming. Prova un’altra sorgente.",
  "Current stream": "Streaming attuale",
  "Size unknown": "Dimensione sconosciuta",
  "View source URL": "Visualizza URL della fonte",
  "Source URL": "URL della fonte",
  "Copy URL": "Copia URL",
  "URL copied": "URL copiato",
  "Goals alert": "Avviso gol",
  "Score alerts for My Teams on any screen":
      "Avvisi di punteggio per Le mie squadre su ogni schermata",
  "Show a top-left popup when a team in My Teams scores. Alerts follow the score feed and pause when scores are hidden.":
      "Mostra un avviso in alto a sinistra quando segna una squadra in Le mie squadre. Gli avvisi seguono gli aggiornamenti del punteggio e si interrompono quando i punteggi sono nascosti.",
  "{team} scored!": "{team} ha segnato!",
  "{first} {firstScore} – {secondScore} {second}":
      "{first} {firstScore} – {secondScore} {second}",
  'Catch-up is not available for this channel.':
      'La TV on demand non è disponibile per questo canale.',
  'This programme is not available in catch-up.':
      'Questo programma non è disponibile in replay.',
  "Hide Catch-up group": "Nascondi il gruppo Replay",
  "Removes the TV tab's Catch-up row (every channel you can replay).":
      "Toglie la riga Replay dalla scheda TV (tutti i canali da rivedere).",
  "No channels with catch-up.": "Nessun canale con replay.",
  "Catch-up playlists": "Playlist con replay",
  "Hidden here · {n} channels": "Nascosta qui · {n} canali",
  'Catch-up': 'Replay',
  'Previous programme': 'Programma precedente',
  'Next programme': 'Programma successivo',
  'Watch from the start': "Guarda dall'inizio",
  '{time} behind live': '{time} indietro rispetto alla diretta',
  'Back to live': 'Torna alla diretta',
  'Catch-up {time}': 'Replay {time}',
  'Now': 'Adesso',
  "Refined finish": "Finitura raffinata",
  "Glossy surfaces, reflections and blur. Uses more graphics resources.":
      "Superfici lucide, riflessi e sfocatura. Usa più risorse grafiche.",
  "Video HDR": "HDR video",
  "Decoder HDR": "HDR decodificato",
  "Unknown / not reported": "Sconosciuto / non indicato",
  "{format} (stream)": "{format} (flusso)",
  "{format} (decoder)": "{format} (decoder)",
  "File size": "Dimensione del file",

  // Match-specific score alerts.
  "Remove goals alert for {league}": "Rimuovi gli avvisi gol per {league}",
  "Goals alert for all of {league}": "Avvisi gol per tutta la {league}",
  "Notify me of every goal in this league (while VesperTV is open). Hide scores pauses alerts.":
      "Avvisami di ogni gol di questa lega (con VesperTV aperto). Nascondi punteggi mette in pausa gli avvisi.",
  "Watch game button": "Pulsante Guarda la partita",
  "A reminded game offers Watch game in the player at kickoff":
      "Una partita con promemoria propone Guarda la partita nel player al calcio d'inizio",
  "When a reminded game is about to start, a Watch game button shows in the player for 10 minutes. Press Up from the player bar to reach it, then OK to switch to the game on its best channel. Set a reminder with a hold on the game. {app} must be open. Saved for this viewer.":
      "Quando una partita con promemoria sta per iniziare, un pulsante Guarda la partita appare nel player per 10 minuti. Premi Su dalla barra del player per raggiungerlo, poi OK per passare alla partita sul canale migliore. Imposta un promemoria tenendo premuto OK sulla partita. {app} deve essere aperto. Salvato per questo profilo.",
  "Watch game": "Guarda la partita",
  "When the next episode starts by itself":
      "Quando l'episodio successivo parte da solo",
  "Play the next episode": "Riproduci l'episodio successivo",
  "30 seconds before the end": "30 secondi prima della fine",
  "When the episode ends": "Alla fine dell'episodio",
  "Never": "Mai",
  "{when}. On TV show episodes, the Up Next card counts down and the next episode starts by itself. Never: no countdown; the episode plays to its end.":
      "{when}. Negli episodi delle serie, la scheda Prossimo fa il conto alla rovescia e l'episodio successivo parte da solo. Mai: nessun conto alla rovescia, l'episodio va fino alla fine.",
  "Set goals alert for this match": "Attiva gli avvisi gol per questa partita",
  "Remove goals alert for this match":
      "Rimuovi gli avvisi gol per questa partita",
  "Notify me when either team scores (while VesperTV is open). Hide scores pauses alerts.":
      "Avvisami quando segna una delle squadre (mentre VesperTV è aperto). Nascondere i punteggi sospende gli avvisi.",
  "Could not save score alert.": "Impossibile salvare l’avviso del punteggio.",
  // Game reminder timing.
  "1 hour before": "1 ora prima",
  "1 day before": "1 giorno prima",
  "1 week before": "1 settimana prima",
  "At game time only": "Solo all’inizio della partita",
  "15 minutes before": "15 minuti prima",
  "Reminder timing": "Orario del promemoria",
  "Advance reminders also notify at game time. VesperTV must be open.":
      "I promemoria anticipati avvisano anche all’inizio della partita. VesperTV deve essere aperto.",
  "This reminder time has passed":
      "L’orario di questo promemoria è già passato",
  "Choose when to be reminded (while VesperTV is open)":
      "Scegli quando ricevere il promemoria (mentre VesperTV è aperto)",
  "Starts in 1 hour": "Inizia tra 1 ora",
  "Starts in 1 day": "Inizia tra 1 giorno",
  "Starts in 1 week": "Inizia tra 1 settimana",
  "Schedule": "Calendario",
  "Every game of the season, cups included":
      "Tutte le partite della stagione, coppe comprese",
  "Could not load the schedule.": "Impossibile caricare il calendario.",
  "OK: stats, watch or game menu · Hold OK: game menu · CH+/CH-: month":
      "OK: statistiche, guarda o menu partita · Tieni premuto OK: menu partita · CH+/CH-: mese",
  "No game this day.": "Nessuna partita in questo giorno.",
  "Next game": "Prossima partita",
  "Newest": "Novità",
  'What happens when a catch-up programme ends':
      "Cosa succede quando finisce un programma in replay",
  'Keep playing after the programme': "Continua dopo il programma",
  "Off: catch-up pauses when the programme you picked ends, so the next one doesn't start on its own; press Play to carry on. On: it keeps going like the channel did.":
      "Disattivato: il replay va in pausa alla fine del programma scelto, così il successivo non parte da solo; premi Play per continuare. Attivato: prosegue come ha fatto il canale.",
  "Channel schedule": "Palinsesto del canale",
  "▲ ▼ programmes  ·  OK to watch  ·  Back to close":
      "▲ ▼ programmi  ·  OK per guardare  ·  Indietro per chiudere",
  "On now  ·  OK to watch live": "In onda  ·  OK per guardare in diretta",
  "Catch-up  ·  OK to watch from the start":
      "Catch-up  ·  OK per guardare dall'inizio",
  "Upcoming": "In arrivo",
  "Show group counts": "Mostra il numero per gruppo",
  "How many channels, movies or shows each group holds, beside its name.":
      "Quanti canali, film o serie contiene ogni gruppo, accanto al nome.",
  "{m} min back": "{m} min indietro",

  // Upcoming TV programmes
  "Starts in 5 minutes": "Inizia tra 5 minuti",
  "5 minutes before and at programme time (while VesperTV is open)":
      "5 minuti prima e all’inizio del programma (con VesperTV aperto)",
  "Overlaps {title}. Your playlist has no free recording connection.":
      "Si sovrappone a {title}. La playlist non ha connessioni libere per registrare.",
  "Records the programme start to end. Manage it in Recordings.":
      "Registra il programma dall’inizio alla fine. Gestiscilo in Registrazioni.",
  "Could not schedule recording. Check recording storage and try again.":
      "Impossibile programmare la registrazione. Controlla lo spazio di archiviazione e riprova.",
  "▲ ▼ programmes  ·  OK for options  ·  Back to close":
      "▲ ▼ programmi  ·  OK per le opzioni  ·  Indietro per chiudere",
  "Upcoming  ·  OK to remind or record":
      "In programma  ·  OK per promemoria o registrazione",
  "Recording scheduled. Android may delay the start without exact alarm access.":
      "Registrazione programmata. Android può ritardare l’inizio senza accesso alle sveglie esatte.",

  // Plex media-server connector.
  "Connect Jellyfin / Emby / Plex": "Collega Jellyfin / Emby / Plex",
  "Connect Plex": "Collega Plex",
  "Sign in on your phone and choose a Plex server":
      "Accedi dal telefono e scegli un server Plex",
  "Sign in with Plex on your phone, then choose a server. Your movie and TV libraries appear in the Media Hub. Files play directly, without transcoding.":
      "Accedi a Plex dal telefono, poi scegli un server. Le librerie di film e serie appaiono nel Media Hub. I file vengono riprodotti direttamente, senza transcodifica.",
  "Could not connect to Plex. Try again.":
      "Impossibile connettersi a Plex. Riprova.",
  "Plex sign-in expired. Try again.": "Accesso a Plex scaduto. Riprova.",
  "Plex access was denied. Sign in again.":
      "Accesso a Plex negato. Accedi di nuovo.",
  "Could not reach this Plex server. Check that it is online and accessible from this device.":
      "Impossibile raggiungere questo server Plex. Verifica che sia online e accessibile da questo dispositivo.",
  "Choose a Plex server": "Scegli un server Plex",
  "No Plex servers are available on this account.":
      "Nessun server Plex disponibile per questo account.",
  "Sign in again": "Accedi di nuovo",
  "Scan the QR code or visit {url} and enter this code:":
      "Scansiona il codice QR o visita {url} e inserisci questo codice:",

  // Title page row order.
  "Customize title page": "Personalizza la pagina del titolo",
  "Choose the order of rows below title details. Saved for this viewer.":
      "Scegli l’ordine delle righe sotto i dettagli del titolo. Salvato per questo profilo.",

  // My Teams preferred channel.
  "Set preferred channel": "Scegli canale preferito",
  "Automatic channel": "Canale automatico",
  "Preferred channel for {team}": "Canale preferito per {team}",
  "Saved channel is unavailable": "Il canale salvato non è disponibile",
  "Hold OK on a team for schedule, preferred channel or unfollow · on a game to pick the channel":
      "Tieni premuto OK su una squadra: calendario, canale preferito o smetti di seguire · su una partita: scegli canale",

  // Sports channel country preferences.
  "Channel preferences and settings for {tab}.":
      "Preferenze dei canali e impostazioni di {tab}.",
  "Preferred channel countries": "Paesi preferiti per i canali",
  "Prefer local channels while keeping other matches available":
      "Dai priorità ai canali locali mantenendo disponibili le altre corrispondenze",
  "Prefer these countries among channels that match the game. Other countries remain available. Your game and team channel choices still come first.":
      "Dai priorità a questi paesi tra i canali corrispondenti alla partita. Gli altri paesi restano disponibili. I canali scelti per partite e squadre mantengono la precedenza.",
  "Selected countries have equal priority. Match evidence comes before country, then video quality within each group. Saved for this viewer.":
      "I paesi selezionati hanno la stessa priorità. Le prove della corrispondenza vengono prima del paese, poi la qualità video in ogni gruppo. Salvato per questo profilo.",
  "No country preference": "Nessuna preferenza di paese",
  "Keep the current automatic ranking": "Mantieni l’ordine automatico attuale",
  "Canada": "Canada",
  "United States": "Stati Uniti",
  "United Kingdom": "Regno Unito",
  "Portugal": "Portogallo",
  "Greece": "Grecia",
  "Ireland": "Irlanda",
  "Netherlands": "Paesi Bassi",
  "Belgium": "Belgio",
  "Switzerland": "Svizzera",
  "Austria": "Austria",
  "Denmark": "Danimarca",
  "Sweden": "Svezia",
  "Norway": "Norvegia",
  "Finland": "Finlandia",
  "Poland": "Polonia",
  "Czechia": "Cechia",
  "Slovakia": "Slovacchia",
  "Hungary": "Ungheria",
  "Romania": "Romania",
  "Bulgaria": "Bulgaria",
  "Croatia": "Croazia",
  "Serbia": "Serbia",
  "Slovenia": "Slovenia",
  "Bosnia and Herzegovina": "Bosnia ed Erzegovina",
  "Albania": "Albania",
  "Türkiye": "Turchia",
  "Ukraine": "Ucraina",
  "Australia": "Australia",
  "New Zealand": "Nuova Zelanda",
  "Brazil": "Brasile",
  "Mexico": "Messico",
  "Argentina": "Argentina",
  "Cyprus": "Cipro",
  "Estonia": "Estonia",
  "Latvia": "Lettonia",
  "Lithuania": "Lituania",
  "Luxembourg": "Lussemburgo",
  "Malta": "Malta",
  "Iceland": "Islanda",
  // Sports preferred playlist.
  "Preferred playlist": "Playlist preferita",
  "Try matching channels from this playlist first":
      "Cerca prima i canali corrispondenti in questa playlist",
  "Among comparable game matches, prefer this playlist, then your preferred countries, then video quality. Your game and team channel choices still come first. Other playlists remain available.":
      "Tra corrispondenze comparabili, dai priorità a questa playlist, poi ai paesi preferiti e infine alla qualità video. Le tue scelte di canale per partite e squadre restano prioritarie. Le altre playlist restano disponibili.",
  "Your preferred playlist is unavailable or disabled. Other matching playlists will be used.":
      "La playlist preferita non è disponibile o è disattivata. Verranno usate altre playlist con corrispondenze.",
  "No playlist preference": "Nessuna preferenza di playlist",
  "Disabled": "Disattivata",
  "No playlists yet": "Nessuna playlist ancora",
  "Selected countries have equal priority. Match evidence comes first, then preferred playlist, country and video quality. Saved for this viewer.":
      "I paesi selezionati hanno la stessa priorità. Prima conta la corrispondenza della partita, poi la playlist preferita, il paese e la qualità video. Salvato per questo profilo.",
  "Rank countries equally": "Dai la stessa priorità a tutti i paesi",
  // Hide empty sports leagues.
  "Hide leagues with no games": "Nascondi i campionati senza partite",
  "Show only leagues with games on the selected day":
      "Mostra solo i campionati con partite nel giorno selezionato",
  "Follows the selected day in Sports Trak. Leagues stay visible while schedules are loading or unavailable. Your saved leagues and their order are kept in Edit leagues. Saved for this viewer.":
      "Segue il giorno selezionato in Sports Trak. I campionati restano visibili mentre i calendari vengono caricati o non sono disponibili. I campionati salvati e il loro ordine restano in Modifica campionati. Salvato per questo profilo.",
  // Updater storage and download checks.
  "Free about {mb} MB and try again.": "Libera circa {mb} MB e riprova.",
  "Could not check free storage. Restart VesperTV and try again.":
      "Impossibile verificare lo spazio libero. Riavvia VesperTV e riprova.",
  "Could not check the update size. Check for updates and try again.":
      "Impossibile verificare la dimensione dell’aggiornamento. Cerca gli aggiornamenti e riprova.",
  "Download failed. Please try again.": "Download non riuscito. Riprova.",
  // IPTV cast portraits.
  "Metadata provided by TMDB.": "Metadati forniti da TMDB.",
  "No matching title found in your playlists.":
      "Nessun titolo corrispondente trovato nelle tue playlist.",
  "Skip intro": "Salta l'intro",
  "Skip recap": "Salta il riassunto",
  "Skip credits": "Salta i titoli di coda",
  "Skip intro and credits button":
      "Pulsante per saltare intro e titoli di coda",
  "Skip intros and credits on TV show episodes":
      "Salta intro e titoli di coda negli episodi",
  "On TV show episodes, a button skips the intro, the recap and the credits (or plays the next episode). Press OK while it shows. Times come from IntroDB (introdb.app), a free community database: it is asked with the show's IMDb id, season and episode number, nothing else.":
      "Negli episodi delle serie, un pulsante salta l'intro, il riassunto e i titoli di coda (o avvia l'episodio successivo). Premi OK mentre è visibile. I tempi vengono da IntroDB (introdb.app), un database comunitario gratuito: riceve solo l'id IMDb della serie, la stagione e il numero dell'episodio.",
  "Betting odds": "Quote scommesse",
  "Show betting odds": "Mostra le quote",
  "The line and over/under on game cards, more in the game stats":
      "La linea e il totale (over/under) sulle schede delle partite, di più nelle statistiche",
  "Show the line and over/under on games":
      "Mostra la linea e il totale delle partite",
  "Odds come with the scores (one sportsbook, mostly North American leagues) and show before and during a game. Display only: {app} never takes bets or links to a sportsbook. Saved for this viewer.":
      "Le quote arrivano con i punteggi (un solo bookmaker, soprattutto leghe nordamericane) e compaiono prima e durante una partita. Solo visualizzazione: {app} non accetta scommesse e non rimanda a nessun bookmaker. Salvato per questo profilo.",
  "Moneyline": "Vincente",
  "Spread": "Handicap",
  "Over": "Over",
  "Under": "Under",
  "Draw": "Pareggio",
  "Favourite": "Favorito",
  "Total": "Totale",
  "Betting odds · {book}": "Quote · {book}",
  "Playlist editor": "Editor playlist",
  "Rename, hide copies, fallbacks and stream test, from your phone or PC": "Rinomina, nascondi copie, canali di riserva e test degli stream, dal telefono o dal PC",
  "Rename, change logos, hide copies and dead streams, set fallback channels and clean up the guide, from your phone or PC. Your provider's playlist is never changed: edits are kept on this device and run again on every content update.": "Rinomina canali, cambia i loghi, nascondi copie e stream morti, scegli canali di riserva e pulisci la guida, dal telefono o dal PC. La playlist del tuo provider non viene mai modificata: le modifiche restano su questo dispositivo e si riapplicano a ogni aggiornamento.",
  "Could not open the editor: {e}": "Impossibile aprire l'editor: {e}",
  "Phone: scan the code.": "Telefono: scansiona il codice.",
  "PC: open this address in a browser": "PC: apri questo indirizzo in un browser",
  "and enter the code": "e inserisci il codice",
  "Same Wi-Fi or network as this device. The editor closes when you leave this screen.": "Stessa Wi-Fi o rete di questo dispositivo. L'editor si chiude quando esci da questa schermata.",
  "Open in browser": "Apri nel browser",
  "Saved from your phone or PC: {name}": "Salvato dal telefono o dal PC: {name}",
  "Stream test {done}/{total}: {name}": "Test stream {done}/{total}: {name}",
  "Stream test: {done}/{total} tested.": "Test stream: {done}/{total} testati.",
  "Switch to another copy when a channel fails": "Passa a un'altra copia quando un canale non funziona",
  "If a channel doesn't start or keeps dropping, play its next copy (FHD, then HD…) or your fallback channels, without an error screen.": "Se un canale non parte o si interrompe, viene riprodotta la copia successiva (FHD, poi HD…) o i tuoi canali di riserva, senza schermata di errore.",
  "Hide lower-quality copies": "Nascondi le copie di qualità inferiore",
  "Only the best copy of each channel is listed; the others stay as automatic fallbacks.": "Viene mostrata solo la copia migliore di ogni canale; le altre restano come riserva automatica.",
  "Hide separator rows": "Nascondi le righe separatrici",
  "Rows like ##### SPORTS #####": "Righe come ##### SPORTS #####",
  "{n} channels hidden by the editor": "{n} canali nascosti dall'editor",
  "Rename channel": "Rinomina canale",
  "Channel name": "Nome del canale",
  "Rename…": "Rinomina…",
  "Use the provider's name": "Usa il nome del provider",
  "Trying another copy: {name}": "Provo un'altra copia: {name}",
  "Previous month": "Mese precedente",
  "Next month": "Mese successivo",
  "Pause": "Pausa",
  "No guide information": "Nessuna informazione di guida",
  "Playing {name}": "In riproduzione: {name}",
  "Up": "Su",
  "Down": "Giù",
  "Recently added": "Aggiunti di recente",
  "Recently added channels": "Canali aggiunti di recente",
  "Adds a TV tab group with the channels your playlists added in the last 14 days.": "Aggiunge un gruppo nella scheda TV con i canali aggiunti dalle tue playlist negli ultimi 14 giorni.",
  "No channels added in the last 14 days.": "Nessun canale aggiunto negli ultimi 14 giorni.",
  "Live buffer": "Buffer della diretta",
  "Hide short dropouts on live channels": "Nasconde le brevi interruzioni sui canali live",
  "Small (1.5 seconds)": "Piccolo (1,5 secondi)",
  "Gradual (starts fast, builds up)": "Graduale (parte subito, si accumula)",
  "building at 96 % speed": "accumulo al 96 % della velocità",
  "4 seconds": "4 secondi",
  "8 seconds": "8 secondi",
  "12 seconds": "12 secondi",
  "{size}. Live channels store this much before playing, so short dropouts from the server don't show. Bigger hides longer dropouts, but channels start later and play that much behind live. Applies from the next channel.": "{size}. I canali live accumulano questa riserva prima di partire, così le brevi interruzioni del server non si vedono. Più grande nasconde interruzioni più lunghe, ma i canali partono dopo e restano indietro di quel tempo rispetto alla diretta. Vale dal prossimo canale.",
  "Seasons": "Stagioni",
  "Playlist editor (Test flight)": "Editor playlist (Test flight)",
  "Add screen": "Aggiungi schermo",
  "Enlarge screen": "Ingrandisci schermo",
  "Equal screens": "Schermi uguali",
  "Exit full screen": "Esci da schermo intero",
  "Remove screen": "Rimuovi schermo",
  "= audio follows the selected screen · OK for options · hold OK to enlarge": "= l'audio segue lo schermo scelto · OK per le opzioni · tieni premuto OK per ingrandire",
  "Search and add": "Cerca e aggiungi",
  "Hide league names": "Nascondi i nomi dei campionati",
  "Show league names": "Mostra i nomi dei campionati",
  "Check up to 4 live games, then choose Open Multiview": "Seleziona fino a 4 partite in diretta, poi scegli Apri Multiview",
  "Only live games can be added": "Si possono aggiungere solo partite in diretta",
  "Multiview shows up to 4 screens": "Multiview mostra fino a 4 schermi",
  "Check at least one live game": "Seleziona almeno una partita in diretta",
  "Open Multiview ({n})": "Apri Multiview ({n})",
  "Play in Multiview": "Guarda in Multiview",
  "Check other live games to watch together": "Seleziona altre partite in diretta da guardare insieme",
  "{n} sources": "{n} fonti",
  "Not listed yet": "Non ancora in elenco",
  "The newest episode may not be in the catalog yet. Press Play to ask your sources.": "L'episodio più recente potrebbe non essere ancora nel catalogo. Premi Riproduci per chiedere alle tue fonti.",
};
