/// Spanish UI strings, keyed by the English text in the code (see l10n.dart).
///
/// Neutral (Latin American) Spanish. TV labels are often narrow, so short
/// forms are used on purpose (ACT., PJ/G/P for standings, etc.). Keep every
/// `{placeholder}` exactly as in the key. `{s}` is an English-style plural
/// "s" filled in by the code; Spanish plurals don't always work that way
/// (canal/canales), so those strings are phrased to avoid it.
const Map<String, String> kEs = {
  "Discord": "Discord",
  "Direct support through Discord": "Soporte directo en Discord",
  "Questions, help with setup, feature ideas and release news: join the VesperTV community on Discord.":
      "Preguntas, ayuda con la configuración, ideas y novedades: únete a la comunidad de VesperTV en Discord.",
  "VesperTV is free, with no ads. A coffee or a Supporter membership helps cover its costs.":
      "VesperTV es gratis y sin anuncios. Un café o una membresía Supporter ayuda a cubrir sus costes.",
  "Show a test popup": "Mostrar una ventana de prueba",
  "A sample goal alert for 8 seconds.":
      "Un aviso de gol de ejemplo durante 8 segundos.",
  "Guide": "Guía",
  "Live TV guide layout, full-screen video, compact rows":
      "Diseño de la guía, vídeo a pantalla completa, filas compactas",
  "{n} titles": "{n} títulos",
  "Open groups as expanded catalog": "Abrir grupos como catálogo ampliado",
  "Movies and TV Shows groups open the full poster grid instead of the rows.":
      "Los grupos de Películas y Series abren la cuadrícula completa de carteles en lugar de las filas.",
  "Compact guide": "Guía compacta",
  "Shorter Timeline rows so more channels fit in the same space.":
      "Filas más cortas en la línea de tiempo para ver más canales.",
  "Transparent popups": "Ventanas transparentes",
  "Reminders and goal alerts lose their background and outline, keeping only the logo and text.":
      "Los recordatorios y avisos de gol pierden el fondo y el contorno, y conservan solo el logo y el texto.",
  "Use with playlist": "Usar con la lista",
  "Save EPG URL": "Guardar URL de la guía",
  "Custom EPG URL saved.": "URL de guía propia guardada.",
  "Custom EPG URL cleared.": "URL de guía propia borrada.",
  "Pick a playlist, then paste a third-party XMLTV link. Leave it blank to use the guide of that playlist. A channel is only filled in when the ids in the feed match the playlist.":
      "Elige una lista y pega un enlace XMLTV de terceros. Déjalo vacío para usar la guía de la lista. Solo se completa un canal si los ids de la fuente coinciden con los de la lista.",
  // Sports Trak quality preference (moved from the league bar).
  "Prefer higher-quality channels among game matches":
      "Preferir los canales de mayor calidad que coincidan con el partido",
  "On by default. Your saved channel choices still come first. Turn this off to keep the usual match order. Saved for this viewer.":
      "Activado de forma predeterminada. Tus canales guardados siguen teniendo prioridad. Desactívalo para mantener el orden habitual de las coincidencias. Guardado para este perfil.",
  // Android phone player touch lock.
  "Lock touch controls": "Bloquear controles táctiles",
  "Unlock touch controls": "Desbloquear controles táctiles",
  "Touch controls locked": "Controles táctiles bloqueados",
  // Media Hub custom posters.
  "Add {imdb_id} or {tmdb_id} where the title goes.":
      "Añade {imdb_id} o {tmdb_id} donde va el título.",
  "Custom posters": "Pósters personalizados",
  "Custom posters off: Media Hub shows the sources' posters.":
      "Pósters personalizados desactivados: Media Hub muestra los pósters de las fuentes.",
  "Example: {url}": "Ejemplo: {url}",
  "Media Hub posters from a poster service":
      "Pósters de Media Hub desde un servicio de pósters",
  "Poster address": "Dirección de los pósters",
  "Saved. Media Hub posters now come from this address.":
      "Guardado. Los pósters de Media Hub ahora vienen de esta dirección.",
  "Show Media Hub posters from a poster service of your choice, for example one that adds ratings. Paste its poster address with {imdb_id} (or {tmdb_id}) where the title goes; include your own key if the service needs one.":
      "Muestra los pósters de Media Hub desde el servicio que elijas, por ejemplo uno que añade puntuaciones. Pega su dirección de póster con {imdb_id} (o {tmdb_id}) donde va el título; incluye tu propia clave si el servicio la pide.",
  "Turn off": "Desactivar",
  "When a title has no matching ID, its normal poster is shown. Leave empty to turn it off.":
      "Si un título no tiene el identificador necesario, se muestra su póster normal. Déjalo vacío para desactivarlo.",
  // Media Hub experience (progressive sources, rows, discovery).
  "Add your TMDB key for collections and cast credits":
      "Añade tu clave de TMDB para colecciones y reparto",
  "Airs {date}": "Se emite {date}",
  "All sources": "Todas las fuentes",
  "Any source": "Cualquier fuente",
  "Auto-play preferred stream": "Reproducir automáticamente el flujo preferido",
  "Cast and credits": "Reparto y créditos",
  "Collection": "Colección",
  "Continue series": "Continuar la serie",
  "Could not load credits.": "No se pudieron cargar los créditos.",
  "Could not load this title. Try again.":
      "No se pudo cargar este título. Inténtalo de nuevo.",
  "Customize": "Personalizar",
  "Customize Media Hub": "Personalizar Media Hub",
  "Customize rows": "Personalizar filas",
  "Explore more": "Explorar más",
  "Explore this genre": "Explorar este género",
  "Hide a row without disabling its playback source.":
      "Oculta una fila sin desactivar su fuente de reproducción.",
  "Hide row": "Ocultar fila",
  "If no stream matches, choose one manually. Format and language information comes from your sources.":
      "Si ningún flujo coincide, elige uno manualmente. La información de formato e idioma procede de tus fuentes.",
  "Leave empty to reset": "Déjalo vacío para restablecer",
  "Loading": "Cargando",
  "Loading recommendations…": "Cargando recomendaciones…",
  "Looking for streams…": "Buscando flujos…",
  "Maximum quality": "Calidad máxima",
  "More like this": "Más como este",
  "No compatible source for this title. Add a playback source in Media Hub settings.":
      "No hay ninguna fuente compatible para este título. Añade una fuente de reproducción en los ajustes de Media Hub.",
  "No credits found.": "No se encontraron créditos.",
  "No results": "Sin resultados",
  "No streams": "Sin flujos",
  "Pin row": "Fijar fila",
  "Playback preferences": "Preferencias de reproducción",
  "Prefer SDR": "Preferir SDR",
  "Preferred source": "Fuente preferida",
  "Rename row": "Renombrar fila",
  "Results": "Resultados",
  "Retry recommendations": "Reintentar recomendaciones",
  "Search sources": "Fuentes de búsqueda",
  "Show row": "Mostrar fila",
  "Sources": "Fuentes",
  "Sources · searching…": "Fuentes · buscando…",
  "Unavailable": "No disponible",
  "subtitles": "subtítulos",
  // Sports matchup information and activation.
  "Key stats": "Estadísticas clave",
  "Latest goal": "Último gol",
  "Last play": "Última jugada",
  "Game situation": "Situación del partido",
  "OK: watch here  ·  Hold: pick the channel":
      "OK: ver aquí  ·  Mantener: elegir canal",
  "Click: watch here  ·  Hold: pick the channel":
      "Clic: ver aquí  ·  Mantener: elegir canal",
  "Open full Live TV": "Abrir TV en vivo completa",
  // Startup profile selector.
  "Launch with profiles selector": "Iniciar con el selector de perfiles",
  "Choose a profile after the splash, before the app opens. Applies from the next start.":
      "Elige un perfil después de la pantalla de inicio, antes de abrir la aplicación. Se aplica en el próximo inicio.",
  "Who is watching?": "¿Quién está viendo?",
  "Choose your profile to get started.": "Elige tu perfil para empezar.",
  "Welcome, {name}": "Bienvenido, {name}",
  "Could not switch profile. Please try again.":
      "No se pudo cambiar de perfil. Inténtalo de nuevo.",

  "Sports Mode": "Modo Deportes",
  "Make Sports Trak your home, with your top five leagues at the side.":
      "Usa Sports Trak como inicio, con tus cinco primeras ligas en el lateral.",
  "Could not change Sports Mode. Try again.":
      "No se pudo cambiar el modo Deportes. Inténtalo de nuevo.",
  // Media Hub source cards.
  "Enabled": "Activada",
  "Catalogs from Cinemeta": "Catálogos de Cinemeta",
  "Media server": "Servidor multimedia",
  "Tracker lists": "Listas de seguimiento",
  "Catalogs only": "Solo catálogos",
  "Streams only": "Solo flujos",
  "Catalogs + streams": "Catálogos + flujos",
  "Provides video playback": "Proporciona reproducción de vídeo",
  "Refresh Media Hub after changing Other.":
      "Actualiza Media Hub tras cambiar Otros.",
  "Playback sources": "Fuentes de reproducción",
  "These sources provide the video when you press Play.":
      "Estas fuentes proporcionan el vídeo al pulsar Reproducir.",
  "No playback sources yet.": "Aún no hay fuentes de reproducción.",
  "Catalogs & lists": "Catálogos y listas",
  "Discover titles here; playback comes from your sources above.":
      "Descubre títulos aquí; la reproducción usa tus fuentes de arriba.",
  "Popular · New · Featured": "Populares · Novedades · Destacados",
  "Catalogs for stream-only sources":
      "Catálogos para fuentes que solo ofrecen flujos",
  "Posters and episode details may still use Cinemeta when this is off.":
      "Los carteles y detalles de episodios pueden seguir usando Cinemeta con esta opción desactivada.",
  "Hold OK on Enabled to remove a source.":
      "Mantén OK en Activada para eliminar una fuente.",
  "Show under Other keeps a source behind the Other genre filter in Movies and TV Shows.":
      "Mostrar en Otros coloca una fuente en el filtro de género Otros de Películas y Series.",

  "Remove from history": "Eliminar del historial",
  "Automatically play the largest file":
      "Reproducir automáticamente el archivo más grande",
  "Use the largest known file size when starting a title. Resume keeps your selected stream.":
      "Elige el archivo de mayor tamaño conocido al iniciar. Al reanudar se conserva el flujo seleccionado.",
  "Prefer highest quality": "Preferir la máxima calidad",
  "Remind me for every game: {team}": "Recordarme cada partido: {team}",
  "Stop team reminders: {team}": "Desactivar recordatorios: {team}",
  "Remind me": "Recordármelo",
  "Cancel reminder": "Cancelar recordatorio",
  "15 minutes before and at game time (while VesperTV is open)":
      "15 minutos antes y al comenzar el partido (con VesperTV abierto)",
  "Reminder set": "Recordatorio activado",
  "Reminder cancelled": "Recordatorio cancelado",
  "Could not save reminder.": "No se pudo guardar el recordatorio.",
  "This game has already started.": "Este partido ya ha comenzado.",
  "Your team: {home} vs {away}": "Tu equipo: {home} contra {away}",
  "Starts in 15 minutes": "Empieza en 15 minutos",
  "Is about to start": "Está a punto de empezar",

  "Display": "Pantalla",
  "Match the TV to the video's frame rate and resolution":
      "Ajustar el televisor a la frecuencia de imagen y la resolución del vídeo",
  "Match frame rate": "Ajustar frecuencia de imagen",
  "Switches the TV to the video's frame rate a few seconds after it starts (50 Hz for UK and European channels, 24 Hz for films), for smooth motion. The screen goes black for a second or two while the TV switches; channels with the same rate don't switch again. Leaving the app gives the TV its own setting back.":
      "Cambia el televisor a la frecuencia de imagen del vídeo unos segundos después de empezar (50 Hz para canales del Reino Unido y Europa, 24 Hz para películas), para un movimiento fluido. La pantalla se pone negra uno o dos segundos mientras cambia; los canales con la misma frecuencia no vuelven a cambiar. Al salir de la app, el televisor recupera su propio ajuste.",
  "Only switch between 50 and 60 Hz": "Cambiar solo entre 50 y 60 Hz",
  "Films at 24 frames per second keep the current rate, so fewer switches.":
      "Las películas a 24 imágenes por segundo mantienen la frecuencia actual: menos cambios.",
  "Match resolution": "Ajustar resolución",
  "Switches the TV to the video's resolution (1080p, 4K…) so the TV does the upscaling. Off: this device scales every video to its current resolution.":
      "Cambia el televisor a la resolución del vídeo (1080p, 4K…) para que el televisor haga el escalado. Desactivado: este dispositivo escala cada vídeo a su resolución actual.",
  "Stream HDR": "HDR del stream",
  "No (SDR)": "No (SDR)",
  "Home": "Inicio",
  "Today's games": "Partidos de hoy",
  "Recent channels": "Canales recientes",
  "Favourite channels": "Canales favoritos",
  "New movies": "Películas nuevas",
  "New TV shows": "Series nuevas",
  'Series': "Serie",
  "Movie": "Película",
  "Move row up": "Subir la fila",
  "Move row down": "Bajar la fila",
  "Hide this row": "Ocultar esta fila",
  "Edit Home rows…": "Editar filas de Inicio…",
  "Home rows": "Filas de Inicio",
  "Nothing here yet. Watch a channel, a movie or a show and it shows up on Home.":
      "Aún no hay nada. Mira un canal, una película o una serie y aparecerá en Inicio.",
  "Native video surface (beta)": "Superficie de vídeo nativa (beta)",
  "Plays the picture the way native TV apps do, for HDR that looks washed out or green flashes under the guide (Fire TV Cube, NVIDIA Shield). Restart the app after changing it. If the picture is missing, in the wrong place or menus look wrong, turn it off and send us a log.":
      "Muestra la imagen como las apps de TV nativas, para un HDR que se ve deslavado o destellos verdes bajo la guía (Fire TV Cube, NVIDIA Shield). Reinicia la app después de cambiarlo. Si falta la imagen, está en el lugar equivocado o los menús se ven mal, desactívalo y envíanos un registro.",
  "Close the app completely and open it again to apply this change.":
      "Cierra la app por completo y vuelve a abrirla para aplicar este cambio.",
  "Green flicker fix (test)": "Arreglo del parpadeo verde (prueba)",
  "For green flashes on the picture while the guide or a menu is over it (NVIDIA Shield). Unlike Compatibility video it keeps HDR. Applies from the next channel. If the guide or menus disappear behind the video, turn it off.":
      "Para destellos verdes en la imagen cuando la guía o un menú está encima (NVIDIA Shield). A diferencia de Vídeo compatible, mantiene el HDR. Se aplica desde el siguiente canal. Si la guía o los menús desaparecen detrás del vídeo, desactívalo.",
  'Automatic: on for this device.':
      'Automático: activado para este dispositivo.',
  '1 hour': '1 hora',
  '{h} hours': '{h} horas',

  'Sort groups': 'Ordenar grupos',
  'Provider order': 'Orden del proveedor',
  'Name A–Z': 'Nombre A–Z',
  'Name Z–A': 'Nombre Z–A',

  // ── Startup / catalog sync ───────────────────────────────────────────
  'Starting...': "Iniciando…",
  'Content updated': "Contenido actualizado",
  'Startup failed:\n{bootstrapError}': "Error al iniciar:\n{bootstrapError}",
  'Retry': "Reintentar",
  'Your catalog has never been fully synced.':
      "Tu catálogo nunca se ha sincronizado por completo.",
  'Your catalog was last fully synced earlier today.':
      "Última sincronización completa del catálogo: hoy, más temprano.",
  'Your catalog was last fully synced {days} day{s} ago.':
      "Última sincronización completa del catálogo: hace {days} día{s}.",
  'Update content now?': "¿Actualizar el contenido ahora?",
  'This can take a few minutes on a large catalog. Skipping opens the app with what\'s already cached.':
      "Puede tardar unos minutos con un catálogo grande. Si lo omites, la app se abre con lo que ya está en caché.",
  'Skip for now': "Ahora no",
  'Update': "Actualizar",
  'Loading movies & TV shows...': "Cargando películas y series…",
  'Connecting to server...': "Conectando al servidor…",
  'Updating Content': "Actualizando contenido",
  '{done} / {total} categories': "{done} / {total} categorías",
  'This happens every few days to keep your catalog current — everyday launches open straight in.':
      "Esto ocurre cada pocos días para mantener tu catálogo al día; los demás días la app se abre directamente.",
  'Re-checks every visible category for new content. This can take a few minutes on a large catalog.':
      "Vuelve a revisar cada categoría visible en busca de contenido nuevo. Puede tardar unos minutos con un catálogo grande.",
  'Cancel': "Cancelar",

  // ── Multiview ────────────────────────────────────────────────────────
  'Multiview': "Multivista",
  'Layout': "Diseño",
  '2 channels': "2 canales",
  '4 channels': "4 canales",
  '= audio — click a channel to switch':
      "= audio — haz clic en un canal para cambiar",
  'Reload': "Recargar",
  'Change channel': "Cambiar de canal",
  'Remove': "Quitar",
  'Search channels...': "Buscar canales…",
  'Before you start': "Antes de empezar",
  'Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn\'t, hold Select on it and choose Reload.':
      "Cada pantalla de la Multivista es una conexión propia con tu proveedor. Tu lista debe permitir al menos tantas conexiones como pantallas abras (ver Conexiones máx. en Gestor de listas).\n\nSi dos pantallas comparten una cuenta que solo permite una conexión, se desconectan entre sí y se congelan o cargan sin parar. Consejo: usa canales de listas distintas, una por cuenta.\n\nUna pantalla congelada se reinicia sola. Si no, mantén OK sobre ella y elige Recargar.",
  'Don\'t show this again': "No volver a mostrar",
  'OK': "OK",
  'Couldn\'t start that channel': "No se pudo iniciar ese canal",
  'Full screen': "Pantalla completa",
  'Windowed': "En ventana",
  '4 screens': "4 pantallas",
  '1 + 3 screens': "1 + 3 pantallas",
  'Move to the big screen': "Pasar a la pantalla grande",
  'Swap mode': "Modo intercambio",
  'SWAP': "INTERCAMBIO",
  'Arrows swap · OK or Back to finish':
      "Flechas: intercambiar · OK o Atrás: terminar",
  '2 screens': "2 pantallas",
  '= audio — Select to switch, hold Select for options':
      "= audio — OK para cambiar, mantén OK para opciones",
  'Pick a channel': "Elige un canal",
  'No channels found': "No se encontraron canales",
  'Open in Multiview': "Abrir en Multivista",

  // ── Player ───────────────────────────────────────────────────────────
  'Recall — recently watched': "Recientes — vistos hace poco",
  'No other live channels watched yet this session.':
      "Todavía no has visto otros canales en vivo en esta sesión.",
  'Recall — go back to a recent channel':
      "Recientes — volver a un canal reciente",
  'Remove from favorites': "Quitar de favoritos",
  'Add to favorites': "Añadir a favoritos",
  'Reload channel': "Recargar canal",
  'Previous episode': "Episodio anterior",
  'Next episode': "Episodio siguiente",
  'Ending now': "Terminando",
  '{minutes} min left': "Quedan {minutes} min",
  'Back': "Atrás",
  'Fit to screen': "Ajustar a la pantalla",
  'Fill screen': "Llenar la pantalla",
  'Closed captions (CC) — if the channel broadcasts them':
      "Subtítulos (CC) — si el canal los emite",
  'Up Next': "A continuación",
  'Playing in {countdown}s': "Reproduciendo en {countdown} s",
  'Playing now...': "Reproduciendo…",
  'Play now': "Reproducir ya",
  'Dismiss': "Descartar",
  'Select a channel to start watching': "Elige un canal para empezar a ver",
  'Switch to {p}: {name}': "Cambiar a {p}: {name}",
  'Switch to {playlistName}: {name}': "Cambiar a {playlistName}: {name}",
  'Technical details': "Detalles técnicos",
  "This is a Dolby Vision video, and this device can't play this kind of Dolby Vision. Pick a version without DV (HDR10 or SDR) if your source has one.":
      "Este video es Dolby Vision y este dispositivo no puede reproducir este tipo de Dolby Vision. Elige una versión sin DV (HDR10 o SDR) si tu fuente la ofrece.",
  "This stream kept dropping and restarting, so playback was stopped. Try the channel again in a moment, or pick another one.":
      "Esta transmisión se cortaba y reiniciaba sin parar, así que se detuvo la reproducción. Vuelve a probar el canal en un momento o elige otro.",
  'This device\'s video decoder couldn\'t play this stream — likely 4K HDR (HEVC 10-bit). If your provider offers an HD (non-4K) version of this channel or title, try that. If another app plays this stream on this device, please report it with a photo of the technical details below.':
      "El decodificador de video de este dispositivo no pudo reproducir esta transmisión; probablemente sea 4K HDR (HEVC 10 bits). Si tu proveedor ofrece una versión HD (no 4K) de este canal o título, prueba con esa. Si otra app reproduce esta transmisión en este dispositivo, avísanos con una foto de los detalles técnicos de abajo.",
  'Playback error:\n{raw}': "Error de reproducción:\n{raw}",
  "Server error {code}": "Error del servidor {code}",
  "The provider's server had a problem. Try again in a moment.":
      "El servidor del proveedor tuvo un problema. Inténtalo de nuevo en un momento.",
  "The provider refused the stream: check that your account is active and not already in use on another device.":
      "El proveedor rechazó la transmisión: comprueba que tu cuenta está activa y no se está usando en otro dispositivo.",
  "The provider has no stream at this address: the channel or title may have been removed.":
      "El proveedor no tiene ninguna transmisión en esta dirección: puede que el canal o el título se haya eliminado.",
  "The provider rejected the request.": "El proveedor rechazó la solicitud.",
  "Couldn't reach the provider's server. Check your internet connection, or the server may be down.":
      "No se pudo conectar con el servidor del proveedor. Comprueba tu conexión a Internet, o puede que el servidor esté caído.",
  "Couldn't find the provider's server address. Check your internet connection or DNS settings, or try again later.":
      "No se pudo encontrar la dirección del servidor del proveedor. Comprueba tu conexión a Internet o la configuración de DNS, o inténtalo de nuevo más tarde.",
  'Subtitles': "Subtítulos",
  "1 game": "1 partido",
  "{live} live": "{live} en vivo",
  "Leagues with games": "Ligas con partidos",
  "All leagues": "Todas las ligas",
  "{n} games": "{n} partidos",
  "{n} games · {live} live": "{n} partidos · {live} en vivo",
  "No games": "Sin partidos",
  "Favourite networks": "Cadenas favoritas",
  "Favourite this network": "Añadir esta cadena a favoritos",
  "Remove from favourite networks": "Quitar de cadenas favoritas",
  "Networks": "Cadenas",
  "Other sports channels": "Otros canales deportivos",
  "On now": "Ahora",
  "No channel matches these filters.":
      "Ningún canal coincide con estos filtros.",
  "No sports channels found in your playlists.":
      "No se encontraron canales deportivos en tus listas.",
  "Empty list: hold OK on any channel card to add it here.":
      "Lista vacía: mantén OK en una tarjeta de canal para añadirla aquí.",
  "OK · Full screen   Hold OK · Pick a channel   Back · Stop":
      "OK · Pantalla completa   Mantener OK · Elegir canal   Atrás · Detener",
  "OK · Preview   Hold OK · Pick a channel or add to a list":
      "OK · Vista previa   Mantener OK · Elegir canal o añadir a una lista",
  "See all": "Ver todo",
  "Update automatically": "Actualizar automáticamente",
  "On: when an update is due, it runs at launch without asking. Off: the app asks \"Update content now?\" first.":
      "Activado: cuando toca actualizar, se hace al abrir la app sin preguntar. Desactivado: la app pregunta antes «¿Actualizar el contenido ahora?».",
  "Open on": "Abrir en",
  "{section}. Where the app opens after starting. With \"Resume last channel in full screen\" on, the channel then plays in the background instead.":
      "{section}. Dónde se abre la app al iniciar. Si «Reanudar el último canal en pantalla completa» está activado, el canal se reproduce entonces en segundo plano.",
  "Subtitle size": "Tamaño de los subtítulos",
  "Enter a name first": "Escribe un nombre primero",
  "Dolby Vision (profile {p}, no HDR10 fallback)":
      "Dolby Vision (perfil {p}, sin respaldo HDR10)",
  "Dolby Vision (profile {p}, HDR10 compatible)":
      "Dolby Vision (perfil {p}, compatible con HDR10)",
  "Dolby Vision (profile {p}, HLG compatible)":
      "Dolby Vision (perfil {p}, compatible con HLG)",
  "Dolby Vision (profile {p})": "Dolby Vision (perfil {p})",
  "Extra small": "Muy pequeño",
  "Small": "Pequeño",
  "Normal": "Normal",
  "Large": "Grande",
  "Extra large": "Muy grande",
  'Off': "Desactivados",
  'Forced': "Forzados",
  'Online': 'En línea',
  'Search online subtitles': 'Buscar subtítulos en línea',
  'From your add-ons (Settings > Add-ons)':
      'Con tus complementos (Ajustes > Complementos)',
  'Online subtitles': 'Subtítulos en línea',
  'No subtitles found for this title.':
      'No se encontraron subtítulos para este título.',
  "Couldn't download that subtitle. Try another.":
      'No se pudo descargar ese subtítulo. Prueba otro.',
  'Add-ons': 'Complementos',
  'Online subtitles in more languages': 'Subtítulos en línea en más idiomas',
  'Remove {name}?': '¿Quitar {name}?',
  "That link isn't a subtitle add-on (only subtitle add-ons are supported).":
      'Ese enlace no es un complemento de subtítulos (solo se admiten esos).',
  'That add-on is already in the list.': 'Ese complemento ya está en la lista.',
  '{name} added.': '{name} añadido.',
  "Add-ons find subtitles online for movies and episodes, in many languages. They are free community services, separate from your provider — VesperTV only uses them for subtitles. Turn one on, then pick \"Search online subtitles\" in the player's Subtitles button.":
      'Los complementos buscan subtítulos en línea para películas y episodios, en muchos idiomas. Son servicios comunitarios gratuitos, distintos de tu proveedor — VesperTV solo los usa para subtítulos. Activa uno y elige «Buscar subtítulos en línea» en el botón Subtítulos del reproductor.',
  'Subtitle add-ons': 'Complementos de subtítulos',
  'Subtitles in 60+ languages from OpenSubtitles.org':
      'Subtítulos en más de 60 idiomas de OpenSubtitles.org',
  'Hold OK to remove': 'Mantén OK para quitar',
  'Add an add-on': 'Añadir un complemento',
  'Add-on link (ends with manifest.json)':
      'Enlace del complemento (termina en manifest.json)',
  'Only subtitle add-ons work here. When one is on, the title and episode you are watching are sent to it to find subtitles; nothing else is shared.':
      'Aquí solo funcionan complementos de subtítulos. Cuando uno está activo, se le envían el título y el episodio que ves para buscar subtítulos; no se comparte nada más.',
  'Looking for {language} subtitles…': "Buscando subtítulos en {language}…",
  'No {language} subtitles for this title.':
      "No hay subtítulos en {language} para este título.",
  'No {language} subtitles online for this title.':
      "No hay subtítulos en {language} en línea para este título.",
  'Track {id}': "Pista {id}",
  'Audio {n}': "Audio {n}",
  'Audio Track': "Pista de audio",
  'Audio track': "Pista de audio",

  // ── Catalog / browse ─────────────────────────────────────────────────
  'Sort': "Ordenar",
  'Default': "Predeterminado",
  'A to Z': "A a Z",
  'Z to A': "Z a A",
  'Rating (high to low)': "Calificación (mayor a menor)",
  'Date added/updated': "Fecha de alta/act.",
  'Fetching TMDB release dates... {done}/{total}':
      "Obteniendo fechas de estreno de TMDB… {done}/{total}",
  'Added to Favorites': "Añadido a favoritos",
  'Removed from Favorites': "Quitado de favoritos",
  'No items in this group.': "No hay nada en este grupo.",
  'Re-checks your M3U playlist URL(s) for new content.':
      "Vuelve a revisar la URL de tus listas M3U en busca de contenido nuevo.",
  'Set your playlist source in Settings first.':
      "Primero configura tu lista en Ajustes.",
  'Continue Watching': "Seguir viendo",
  'Search': "Buscar",
  'Update content': "Act. contenido",
  'Update EPG now': "Act. guía",
  'Settings': "Ajustes",
  'No TV shows found. Pick a category on the left.':
      "No se encontraron series. Elige una categoría a la izquierda.",
  'No channels found.': "No se encontraron canales.",
  'Loading playlist...': "Cargando lista…",
  'Failed to load playlist.': "No se pudo cargar la lista.",
  'Open Settings': "Abrir Ajustes",
  '{p}% watched': "{p} % visto",
  'Resume': "Reanudar",
  'Play': "Reproducir",
  'Restart': "Desde el inicio",
  'Failed to load episodes.': "No se pudieron cargar los episodios.",
  'No episodes found.': "No se encontraron episodios.",
  'Season {season}': "Temporada {season}",
  'Expand catalog': "Catálogo completo",
  'Browse': "Explorar",
  'Playlist': "Lista",
  'Previous': "Anterior",
  'Next': "Siguiente",
  'Loading...': "Cargando…",
  'Loading…': "Cargando…",
  'No recently added movies yet': "Aún no hay películas añadidas recientemente",
  'Loading movie categories...': "Cargando categorías de películas…",
  'No recently added shows yet': "Aún no hay series añadidas recientemente",
  'Loading TV show categories...': "Cargando categorías de series…",
  "What's New": "Novedades",

  // ── Search ───────────────────────────────────────────────────────────
  'Switch Profile': "Cambiar de perfil",
  'Restricted': "Restringido",
  'Search everything...': "Buscar en todo…",
  'Search everything... (press OK to type)':
      "Buscar en todo… (OK para escribir)",
  'Still loading the full catalog in the background ({warmCatalogDone}/{warmCatalogTotal} categories) — some results may not show up yet.':
      "El catálogo completo aún se está cargando en segundo plano ({warmCatalogDone}/{warmCatalogTotal} categorías); puede que falten algunos resultados.",
  'Search Live TV, Movies & TV Shows':
      "Busca en TV en vivo, películas y series",
  'Recent searches': "Búsquedas recientes",
  'Clear': "Borrar",
  'Live TV': "TV en vivo",
  'Movies': "Películas",
  'TV Shows': "Series",
  'Nothing found': "Sin resultados",

  // ── Sports ───────────────────────────────────────────────────────────
  'Sports': "Deportes",
  'this team': "este equipo",
  'My Teams': "Mis equipos",
  'Last channels': "Últimos canales",
  '◀ ▶ tabs  ·  OK to watch  ·  Back to close':
      "◀ ▶ pestañas  ·  OK para ver  ·  Atrás para cerrar",
  'None of your teams play today.': "Ninguno de tus equipos juega hoy.",
  'Follow teams from {tab} > Standings to see them here.':
      "Sigue equipos desde {tab} > Clasificación para verlos aquí.",
  'No games from your leagues are live right now.':
      "Ningún partido de tus ligas está en directo ahora.",
  'Hold OK on a team to unfollow · on a game to pick the channel':
      "Mantén OK en un equipo para dejar de seguirlo · en un partido para elegir el canal",
  'Add team': "Añadir equipo",
  'Follow one from Standings': "Sigue uno desde la tabla",
  'Could not load': "No se pudo cargar",
  'Follow your teams to see them here': "Sigue a tus equipos para verlos aquí",
  'Follow another team': "Seguir otro equipo",
  'Add team opens Standings: hold OK on a team to follow it.':
      "«Añadir equipo» abre la tabla: mantén OK en un equipo para seguirlo.",
  'This team could not be loaded. Check the connection.':
      "No se pudo cargar este equipo. Revisa la conexión.",
  'Next 2 weeks': "Próximas 2 semanas",
  'No games in the next two weeks.':
      "No hay partidos en las próximas dos semanas.",
  'vs': "vs",
  'at': "@",
  'Today {time}': "Hoy {time}",
  'Tomorrow {time}': "Mañana {time}",
  'Last game: {opponent} · Final': "Últ. partido: {opponent} · Final",
  'Last game: {result} {mine}-{other} {opponent}':
      "Últ. partido: {result} {mine}-{other} {opponent}",
  'LIVE': "EN VIVO",
  'Looking…': "Buscando…",
  'TEAM': "EQUIPO",
  'Later today': "Hoy, más tarde",
  'Tomorrow': "Mañana",
  'Not played': "No jugados",
  'Scheduled': "Programados",
  'Live now': "En vivo",
  'Final': "Final",
  'All': "Todo",
  'Edit leagues': "Ligas",
  'Scores hidden': "Marcadores ocultos",
  'Scores shown': "Marcadores visibles",
  'Yesterday': "Ayer",
  'Today': "Hoy",
  'Day': "Día",
  'OK: watch  ·  OK again: full screen  ·  Hold OK: stats  ·  ▼ all games':
      "OK: ver  ·  OK otra vez: pantalla completa  ·  Mantener OK: estadísticas  ·  ▼ todos los partidos",
  'OK again on a game: full screen  ·  ▶❚❚: stop':
      "OK otra vez en un partido: pantalla completa  ·  ▶❚❚: detener",
  'Standings': "Clasificación",
  '{name} standings': "Clasificación {name}",
  '{name} championship': "Campeonato de {name}",
  'No games on this day for your leagues':
      "No hay partidos este día en tus ligas",
  'Try another day, or add leagues with Edit leagues.':
      "Prueba otro día o añade ligas con el botón Ligas.",
  'Live now  {count}': "En vivo  {count}",
  'Live': "En vivo",
  'Starts in {p}{p2}m': "Empieza en {p}{p2} min",
  'Looking for the channel…': "Buscando el canal…",
  'No channel found — OK to pick one':
      "No se encontró canal — OK para elegir uno",
  'Hold OK to pick or swap the channel':
      "Mantén OK para elegir o cambiar el canal",
  'Hold OK: pick the channel  ·  ▶❚❚: watch here':
      "Mantén OK: elegir el canal  ·  ▶❚❚: ver aquí",
  'Tap the game again: full screen  ·  Back: stop':
      "Toca el partido otra vez: pantalla completa  ·  Atrás: detener",
  'Tap: watch here  ·  Hold: pick the channel':
      "Tocar: ver aquí  ·  Mantener: elegir el canal",
  'Play here': "Reproducir aquí",
  '{channel} · plays at the top of {tab}':
      "{channel} · se reproduce arriba en {tab}",
  '▶❚❚: watch this game  ·  Back: playing game':
      "▶❚❚: ver este partido  ·  Atrás: partido en curso",
  'OK: full screen  ·  ▶❚❚ or Back: stop':
      "OK: pantalla completa  ·  ▶❚❚ o Atrás: detener",
  'Still looking for channels…': "Todavía buscando canales…",
  'No channel found for this game': "No se encontró canal para este partido",
  'On {matches} channel{s}': "Canales: {matches}",
  'Pick the channel': "Elegir el canal",
  'Choose a different channel': "Elegir otro canal",
  'Search your channels — it can be remembered for this game or team':
      "Busca en tus canales; se puede recordar para este partido o equipo",
  'Forget my pick': "Olvidar mi elección",
  'Go back to the automatic match': "Volver a la elección automática",
  'Remember this channel?': "¿Recordar este canal?",
  'Just this game': "Solo este partido",
  'Best for channels named after one game':
      "Ideal para canales con el nombre de un partido",
  'Always for the {shortName}': "Siempre para {shortName}",
  'Best for a regular channel, like a regional network':
      "Ideal para un canal fijo, como una cadena regional",
  'Leagues': "Ligas",
  'Save': "Guardar",
  'Pick the channel for {title}': "Elige el canal para {title}",
  'Search channels': "Buscar canales",
  'No channels match "{query}"': "Ningún canal coincide con «{query}»",
  '{results}{p} channels': "{results}{p} canales",
  '{group} · Now: {now}': "{group} · Ahora: {now}",
  'Preseason': "Pretemporada",
  'Pick a league above, then hold OK on a team to follow it. Back returns to My Teams.':
      "Elige una liga arriba y mantén OK en un equipo para seguirlo. Atrás vuelve a Mis equipos.",
  'Standings could not be loaded. Check the connection.':
      "No se pudo cargar la clasificación. Revisa la conexión.",
  'switch conference': "cambiar conferencia",
  'switch table': "cambiar de tabla",
  'Hold OK on a team to follow it (My Teams)':
      "Mantén OK en un equipo para seguirlo (Mis equipos)",
  'Your pick': "Tu elección",
  'Found by its name': "Encontrado por su nombre",
  'Found in the guide': "Encontrado en la guía",
  "Team's channel, no guide listing": "Canal del equipo, sin ficha en la guía",
  "Broadcaster, no guide listing": "Cadena emisora, sin ficha en la guía",
  "Only on a hidden channel": "Solo en un canal oculto",
  "Not in your guide yet": "Aún no está en tu guía",
  "On a hidden channel — OK to pick one":
      "En un canal oculto — OK para elegir uno",
  "Not in your guide yet — OK to pick one":
      "Aún no está en tu guía — OK para elegir uno",
  "Only found on {channel}, which is hidden in your lists.":
      "Solo se encontró en {channel}, que está oculto en tus listas.",
  "Your guide doesn't cover this game's time yet. Update the guide closer to the game.":
      "Tu guía aún no cubre la hora de este partido. Actualiza la guía más cerca del partido.",
  "No channel name or guide listing names this game.":
      "Ningún nombre de canal ni ficha de la guía menciona este partido.",
  'Some scores could not be loaded. Check the connection.':
      "No se pudieron cargar algunos marcadores. Revisa la conexión.",
  'Unfollow': "Dejar de seguir",
  'Follow': "Seguir",
  'Remove from My Teams': "Quitar de Mis equipos",
  'Add to My Teams — their games show first in {tab}':
      "Añadir a Mis equipos: sus partidos salen primero en {tab}",
  // Results (W/L/D = won/lost/draw) and standings columns.
  'W': "G",
  'L': "P",
  'D': "E",
  'T': "E",
  'GP': "PJ",
  'GD': "DIF",
  'PTS': "PTS",
  'OTL': "PPR",
  'DIFF': "DIF",
  'STRK': "RACHA",
  'L10': "ÚLT10",
  'REC': "G-P",
  'PF': "PF",
  'PA': "PC",
  'HOME': "LOCAL",
  'AWAY': "VISIT",
  'PCT': "PCT",
  'GB': "JD",

  // ── TV home ──────────────────────────────────────────────────────────
  'TV': "TV",
  'Favorites': "Favoritos",
  'Favourites': "Favoritos",
  'Remove from Favourites': "Quitar de favoritos",
  'Add to Favourites': "Añadir a favoritos",
  'Cancel Hide': "Cancelar ocultar",
  'Hide Group': "Ocultar grupo",
  'Move Up / Down': "Subir / bajar",
  "Show": "Mostrar",
  "Hide": "Ocultar",
  "Hidden here · {n} groups": "Oculta aquí · {n} grupos",
  "At least one playlist stays shown.":
      "Al menos una lista debe seguir visible.",
  "{name} hidden in {tab}": "{name} oculta en {tab}",
  "{name} shown in {tab}": "{name} visible en {tab}",
  "Playlists": "Listas",
  "Jump to playlist": "Ir a la lista",
  "{n} groups": "{n} grupos",
  "Background video": "Vídeo en segundo plano",
  "Mute": "Silenciar",
  "Unmute": "Activar sonido",
  "Show under Other": "Mostrar en Otros",
  "On: this source only appears behind the Other genre filter (Movies and TV Shows). Off: in the main rows. Press Refresh in Media Hub after changing this.":
      "Activado: esta fuente solo aparece tras el filtro de género Otros (Películas y Series). Desactivado: en las filas principales. Pulsa Actualizar en Media Hub después de cambiarlo.",
  "Use the Other filter in Media Hub > Movies / TV Shows > Genre to see this source.":
      "Usa el filtro Otros en Media Hub > Películas / Series > Género para ver esta fuente.",
  "Back to main": "Volver al principal",
  "Compatibility video": "Vídeo compatible",
  "Turn this on if the picture shows twice, in the wrong size or as coloured stripes (older Fire TV sticks). Applies from the next channel. On by default on Android 7 and older.":
      "Actívalo si la imagen aparece duplicada, con un tamaño incorrecto o con rayas de colores (Fire TV Stick antiguos). Se aplica desde el siguiente canal. Activado por defecto en Android 7 y anteriores.",
  "Hide the live picture behind other pages":
      "Ocultar la imagen en directo detrás de otras páginas",
  "A live channel keeps playing behind {tab}, Settings and Search. Some Fire TV sticks keep showing its picture on top of those pages. Turn this on if that happens: the sound keeps going, only the picture is hidden until you go back. Updating the device's software (Fire TV: Settings > My Fire TV > About > Check for Updates) may fix it too.":
      "Un canal en directo sigue sonando detrás de {tab}, Ajustes y Buscar. Algunos Fire TV Stick siguen mostrando su imagen encima de esas páginas. Actívalo si te pasa: el sonido sigue, solo se oculta la imagen hasta que vuelvas. Actualizar el software del dispositivo (Fire TV: Configuración > Mi Fire TV > Acerca de > Buscar actualizaciones) también puede solucionarlo.",
  'Go to row': "Ir a la fila",
  "Typing a server address and password with a remote is painful. Scan this code with your phone camera and sign in there — the details appear here for you to check and connect.":
      "Escribir la dirección de un servidor y una contraseña con el mando es incómodo. Escanea este código con la cámara del teléfono e inicia sesión allí: los datos aparecen aquí para que los compruebes.",
  "Check the details here, then press Connect.":
      "Comprueba los datos aquí y pulsa Conectar.",
  "{n} other catalogs": "{n} otros catálogos",
  "Use the Other filter in Media Hub > Movies > Genre to see this content.":
      "Usa el filtro Otros en Media Hub > Películas > Género para ver este contenido.",
  "Backup & restore": "Copia de seguridad y restauración",
  "Save everything to a file on this device":
      "Guardar todo en un archivo en este dispositivo",
  "Back up now": "Hacer copia ahora",
  "Playlists, favourites, profiles, progress and settings, saved to {path}":
      "Listas, favoritos, perfiles, progreso y ajustes, guardados en {path}",
  "Automatic backup": "Copia automática",
  "Once a week, when VesperTV starts. Keeps the last {n}.":
      "Una vez por semana, al iniciar VesperTV. Conserva las últimas {n}.",
  "Restore from a file": "Restaurar desde un archivo",
  "Pick a backup file, e.g. after reinstalling VesperTV":
      "Elige un archivo de copia, por ejemplo tras reinstalar VesperTV",
  "Backups": "Copias de seguridad",
  "No backups yet.": "Todavía no hay copias.",
  "Backups include your playlist logins. Keep the files private.":
      "Las copias incluyen los datos de acceso de tus listas. Mantén los archivos en privado.",
  "Manual": "Manual",
  "Restore this backup": "Restaurar esta copia",
  "Restore": "Restaurar",
  "Restore backup?": "¿Restaurar la copia?",
  "Everything on this device (playlists, favourites, profiles, settings) is replaced by the backup from {from}. Your current setup is saved as an automatic backup first. VesperTV closes afterwards.":
      "Todo lo que hay en este dispositivo (listas, favoritos, perfiles, ajustes) se sustituye por la copia de {from}. Tu configuración actual se guarda antes como copia automática. VesperTV se cierra después.",
  "the chosen file": "el archivo elegido",
  "Backup restored": "Copia restaurada",
  "Backup saved to {path}": "Copia guardada en {path}",
  "Backup failed: {error}": "Error en la copia: {error}",
  "VesperTV needs storage access to save backups.":
      "VesperTV necesita acceso al almacenamiento para guardar copias.",
  "Couldn't read the backup folder: {error}":
      "No se pudo leer la carpeta de copias: {error}",
  "Couldn't read this backup: {error}": "No se pudo leer esta copia: {error}",
  "Couldn't delete this backup.": "No se pudo eliminar esta copia.",
  "This device has no file picker. Copy the backup into {path} on this device instead.":
      "Este dispositivo no tiene selector de archivos. Copia la copia de seguridad en {path} de este dispositivo.",
  "This file is not a VesperTV backup.":
      "Este archivo no es una copia de VesperTV.",
  "Up / Down moves {name}. OK when done.":
      "Arriba / Abajo mueve {name}. OK para terminar.",
  "Mix playlists in Favourites": "Mezclar las listas en Favoritos",
  "TV, Movies and TV Shows favourites from every playlist in one A-Z list, instead of one list per playlist.":
      "Los favoritos de TV, Películas y Series de todas las listas en una sola lista de la A a la Z, en lugar de una lista por cada una.",
  'Move to Top': "Mover arriba del todo",
  'Unhide this channel': "Volver a mostrar este canal",
  'Hide this channel': "Ocultar este canal",
  'Double': "Doble",
  'for groups': "para los grupos",
  'Exit and free up this login?': "¿Salir y liberar esta cuenta?",
  'This disconnects your login here so it can be used on another device, then fully closes VesperTV. Your channels/movies will need to reload next time you open it.':
      "Esto desconecta tu cuenta aquí para que se pueda usar en otro dispositivo y luego cierra VesperTV por completo. Tus canales y películas tendrán que volver a cargarse la próxima vez.",
  'Exit': "Salir",
  'Exit {appName}?': "¿Salir de {appName}?",
  'Are you sure you want to exit {appName}?':
      "¿Seguro que quieres salir de {appName}?",
  'Stay': "Quedarme",
  'History': "Historial",
  'No channels watched yet.': "Todavía no has visto ningún canal.",
  'Update Content': "Act. contenido",
  'Minimize': "Minimizar",
  'Close': "Cerrar",
  'Disable and exit': "Desactivar y salir",
  'Long-press a group elsewhere to favorite the whole thing.':
      "Mantén OK en un grupo en otra parte para añadirlo entero a favoritos.",
  'Nothing playing': "Nada en reproducción",
  'Click to resume': "Clic para reanudar",
  'Filter channels in this group...': "Filtrar canales de este grupo…",
  'Close filter': "Cerrar filtro",
  'Hidden — find it again in Settings > Playlist Manager > Hidden Channels':
      "Oculto: lo encontrarás en Ajustes > Gestor de listas > Canales ocultos",
  'Unhidden': "Visible otra vez",
  'No favorited movies or TV shows yet.\nHold Select on a poster to add one.':
      "Aún no hay películas ni series en favoritos.\nMantén OK en un póster para añadir una.",
  'No favorited movies yet.': "Aún no hay películas en favoritos.",
  'No favorited TV shows yet.': "Aún no hay series en favoritos.",
  'No favorite channels yet — press Down while watching one to add it.':
      "Aún no hay canales favoritos: pulsa Abajo mientras ves uno para añadirlo.",
  'Updating…': "Actualizando…",
  'No program data': "Sin programación",
  'No program data available': "Programación no disponible",
  'Next: {title} ({p})': "Después: {title} ({p})",
  'Focus a program to see details':
      "Selecciona un programa para ver los detalles",
  'Space': "Espacio",
  'Loading EPG…': "Cargando guía…",

  // ── Welcome ──────────────────────────────────────────────────────────
  'Hey beautiful Human,': "Hola, hermoso humano,",
  'Hey beautiful Human': "Hola, hermoso humano",
  'Welcome to VesperTV': "Bienvenido a VesperTV",
  'Add your first playlist?': "¿Añadir tu primera lista?",
  'Add a playlist to kick things off, or skip for now if you just want to browse and discover the app without content.':
      "Añade una lista para empezar, u omítelo por ahora si solo quieres recorrer y descubrir la app sin contenido.",

  // ── Add playlist ─────────────────────────────────────────────────────
  'Add Playlist': "Añadir lista",
  'Paste some text first.': "Primero pega algún texto.",
  "Couldn't find anything usable in that text.":
      "No se encontró nada útil en ese texto.",
  'Received from your phone — check the details, then press Add Playlist.':
      "Recibido desde tu teléfono: revisa los datos y pulsa «Añadir lista».",
  'Scan the code with your phone and send the form first.':
      "Primero escanea el código con tu teléfono y envía el formulario.",
  'Playlist name is required.': "El nombre de la lista es obligatorio.",
  'Server, username, and password are all required.':
      "Servidor, usuario y contraseña son obligatorios.",
  'M3U playlist URL is required.': "La URL de la lista M3U es obligatoria.",
  'Playlist updated.': "Lista actualizada.",
  'Playlist added.': "Lista añadida.",
  'Download content': "Descargar contenido",
  'This provider has a large catalog. Download everything in the background, or choose which groups to include first?':
      "Este proveedor tiene un catálogo grande. ¿Descargar todo en segundo plano o elegir primero qué grupos incluir?",
  'Choose Groups First': "Elegir grupos",
  'Download All': "Descargar todo",
  'Edit Playlist': "Editar lista",
  'Playlist source': "Origen de la lista",
  'M3U URL': "URL M3U",
  'Xtream Codes': "Xtream Codes",
  'Smart Add': "Añadido inteligente",
  'From phone': "Desde el teléfono",
  'Playlist name': "Nombre de la lista",
  'Name': "Nombre",
  'e.g. My Provider, or 8kStrong': "p. ej. Mi proveedor, o 8kStrong",
  'M3U Playlist URL': "URL de la lista M3U",
  'EPG (XMLTV) URL': "URL de la guía (XMLTV)",
  'Paste the message your provider sent you — we\'ll pull out the server, username, and password.':
      "Pega el mensaje que te envió tu proveedor; sacaremos el servidor, el usuario y la contraseña.",
  'Paste provider message': "Pegar mensaje del proveedor",
  'Parse': "Analizar",
  'Confirm the server': "Confirmar el servidor",
  'No server URL found in that text — enter it below.':
      "No hay URL de servidor en ese texto; escríbela abajo.",
  'Server URL (e.g. http://host:port)':
      "URL del servidor (p. ej. http://host:puerto)",
  'Username': "Usuario",
  'Password': "Contraseña",
  'Custom EPG (XMLTV) URL — optional': "URL de guía propia (XMLTV) — opcional",
  'Leave blank to use the panel\'s own xmltv.php. Set this if your provider\'s EPG is empty or unreliable (e.g. a third-party feed like EPGgenius) — it only fills in a channel if that feed\'s ids match this panel\'s.':
      "Déjalo vacío para usar el xmltv.php del panel. Rellénalo si la guía de tu proveedor está vacía o no es fiable (p. ej. una fuente externa como EPGgenius); solo completa un canal si los ID de esa fuente coinciden con los del panel.",
  'Paste different text': "Pegar otro texto",
  'Status': "Estado",
  'Failed to add playlist: {p}': "No se pudo añadir la lista: {p}",
  'Save Changes': "Guardar cambios",
  'Fill in the form on the left, then press {p} above.':
      "Rellena el formulario de la izquierda y pulsa «{p}» arriba.",
  'Unexpected Xtream API response': "Respuesta inesperada de la API Xtream",
  'Invalid Xtream username/password':
      "Usuario o contraseña de Xtream no válidos",
  'Xtream account is not active (status: {status})':
      "La cuenta Xtream no está activa (estado: {status})",

  // ── Phone pairing ────────────────────────────────────────────────────
  'Code expired': "Código caducado",
  'Add from your phone': "Añadir desde tu teléfono",
  'Typing a long password with a remote is painful. Scan this code with your phone camera and fill in the form there — it appears here for you to check and add.':
      "Escribir una contraseña larga con el control remoto es un fastidio. Escanea este código con la cámara del teléfono y rellena el formulario allí; aparecerá aquí para que lo revises y lo añadas.",
  'Scan with your phone (mobile data is fine).':
      "Escanea con tu teléfono (los datos móviles sirven).",
  'Connect your phone to the same Wi-Fi as this TV, then scan.':
      "Conecta tu teléfono al mismo Wi-Fi que esta TV y luego escanea.",
  'Fill in the form and tap Send to TV.':
      "Rellena el formulario y toca «Send to TV».",
  'Check the details here, then press Add Playlist.':
      "Revisa los datos aquí y pulsa «Añadir lista».",
  'Waiting for your phone…': "Esperando a tu teléfono…",
  'Or open on the phone:': "O abre en el teléfono:",
  'Your details are encrypted on the phone; the relay only passes along scrambled data and deletes it.':
      "Tus datos se cifran en el teléfono; el relé solo transmite datos cifrados y luego los borra.",
  'New code': "Nuevo código",
  'Phone on this Wi-Fi? Use the Wi-Fi code':
      "¿Teléfono en este Wi-Fi? Usa el código Wi-Fi",
  'Phone not on this Wi-Fi? Use the other code':
      "¿Teléfono fuera de este Wi-Fi? Usa el otro código",

  // ── Channel linking / EPG matching ───────────────────────────────────
  'Add and enable a second playlist first — a link connects a channel on one playlist to its equivalent on another.':
      "Primero añade y activa una segunda lista: un enlace une un canal de una lista con su equivalente en otra.",
  'Auto-Pair Channels': "Emparejar auto.",
  'Unpair Channels': "Desemparejar",
  'Reviewing {reviewFilter} auto-paired channel{s} — type to search all instead':
      "Revisando canales emparejados auto. ({reviewFilter}): escribe para buscar en todos",
  'Search your channels': "Buscar en tus canales",
  'Not linked': "Sin enlazar",
  'Linked channel no longer available':
      "El canal enlazado ya no está disponible",
  'Linked to {p}: {name}': "Enlazado a {p}: {name}",
  'Clear link': "Quitar enlace",
  'Link "{name}"': "Enlazar «{name}»",
  'Search other playlists\' channels': "Buscar en los canales de otras listas",
  'No matches.': "Sin coincidencias.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" first so there\'s a channel directory to match against.':
      "Aún no se cargó ninguna guía en esta sesión: ejecuta primero «Act. guía» para tener un directorio de canales.",
  'No EPG feed has been loaded yet this session — run "Update EPG Now" above first so there\'s a channel directory to search.':
      "Aún no se cargó ninguna guía en esta sesión: ejecuta primero «Act. guía» (arriba) para tener un directorio de canales.",
  'Assigned: {p}': "Asignado: {p}",
  'Matched automatically': "Asociado automáticamente",
  'Clear assignment': "Quitar asignación",
  'Assign "{channelName}"': "Asignar «{channelName}»",
  'Search the EPG feed\'s channels': "Buscar en los canales de la guía",
  'No EPG feed has been loaded yet this app session — go back and run "Update EPG Now" first.':
      "Aún no se cargó ninguna guía en esta sesión: vuelve atrás y ejecuta primero «Act. guía».",
  'Now: {title}': "Ahora: {title}",
  'No current program data': "Sin programa actual",
  'Channels are pairing, please wait…': "Emparejando canales, espera…",
  'No new matches found — anything still unmatched needs a manual pick.':
      "No hay nuevas coincidencias; lo que falte hay que elegirlo a mano.",
  'Paired {paired} channel{s} automatically.':
      "Canales emparejados automáticamente: {paired}.",
  'Review': "Revisar",
  'Continue': "Continuar",
  'Nothing was auto-paired — there\'s nothing to undo.':
      "No se emparejó nada automáticamente; no hay nada que deshacer.",
  'Undo {autoPairedCount} automatic pairing{s}? Anything you\'ve set by hand is kept.':
      "¿Deshacer los emparejamientos automáticos ({autoPairedCount})? Lo que hiciste a mano se conserva.",
  'Unpair': "Desemparejar",

  // ── Check for updates ────────────────────────────────────────────────
  'Couldn\'t open the download link.':
      "No se pudo abrir el enlace de descarga.",
  'Allow installing updates': "Permitir instalar actualizaciones",
  'Android needs one-time permission for VesperTV to install an update it downloaded. The next screen is Android\'s own settings — turn the toggle on, then come back here and press Install again.':
      "Android necesita un permiso único para que VesperTV instale una actualización descargada. La siguiente pantalla es de los ajustes de Android: activa la opción, vuelve aquí y pulsa Instalar otra vez.",
  'Check for Updates': "Buscar actualizaciones",
  'Current version: —': "Versión actual: —",
  'Current version: {currentVersion}': "Versión actual: {currentVersion}",
  'Checking...': "Comprobando…",
  'You\'re on the latest version.': "Tienes la última versión.",
  'Check Again': "Volver a comprobar",
  'Version {version} is available': "La versión {version} está disponible",
  'Open Download Page': "Abrir página de descarga",
  'Opens in your browser — unzip the download and run VesperTV.exe to update, replacing the old folder.':
      "Se abre en tu navegador: descomprime la descarga y ejecuta VesperTV.exe para actualizar, reemplazando la carpeta anterior.",
  'Download & Install': "Descargar e instalar",
  'Downloading update... {p}%': "Descargando actualización… {p} %",
  'Download complete.': "Descarga completa.",
  'Install': "Instalar",
  'Android will ask you to confirm the install — that\'s normal, not every app can skip it.':
      "Android te pedirá que confirmes la instalación; es normal, no todas las apps pueden saltarse ese paso.",
  'Something went wrong: {p}': "Algo salió mal: {p}",
  'unknown error': "error desconocido",
  'Try Again': "Reintentar",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minute.':
      "GitHub está limitando temporalmente las comprobaciones desde esta red; vuelve a intentarlo en {n} minuto aprox.",
  'GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minutes.':
      "GitHub está limitando temporalmente las comprobaciones desde esta red; vuelve a intentarlo en {n} minutos aprox.",
  'GitHub is temporarily rate-limiting update checks from this network — try again shortly.':
      "GitHub está limitando temporalmente las comprobaciones desde esta red; vuelve a intentarlo en un rato.",

  // ── EPG settings ─────────────────────────────────────────────────────
  'No EPG URL set yet — add a playlist first.':
      "Todavía no hay URL de guía; primero añade una lista.",
  'Cache cleared.': "Caché borrada.",
  'EPG': "Guía (EPG)",
  'General': "General",
  'EPG Matching': "Asoc. de guía",
  'Channel Pairing': "Emparejar canales",
  'Auto-refresh interval': "Intervalo de act. automática",
  '{p} hours': "{p} horas",
  'EPG never updated': "La guía nunca se actualizó",
  'EPG last updated: {p}': "Última act. de la guía: {p}",
  'Update EPG Now': "Act. guía",
  'Clear Cache': "Borrar caché",
  'Clears the cached EPG and catalog data — playlist source, favorites, and group visibility are kept.':
      "Borra la guía y el catálogo en caché; se conservan el origen de las listas, los favoritos y la visibilidad de los grupos.",
  'Fixes a channel with no program data by manually assigning it to an entry in the loaded EPG feed — useful when a provider\'s own id doesn\'t match a third-party source.':
      "Arregla un canal sin programación asignándolo a mano a una entrada de la guía cargada; útil cuando el ID del proveedor no coincide con una fuente externa.",
  'Links a channel on one playlist to its equivalent on another. If a live channel fails to load, or you switch to it yourself from the player, playback can fall back to the paired channel on the other playlist instead.':
      "Une un canal de una lista con su equivalente en otra. Si un canal en vivo no carga, o cambias tú desde el reproductor, la reproducción puede pasar al canal emparejado de la otra lista.",

  // ── General settings ─────────────────────────────────────────────────
  'Clear search & channel history?':
      "¿Borrar el historial de búsqueda y canales?",
  'Removes your recent searches and the History list of live channels.':
      "Elimina tus búsquedas recientes y el historial de canales en vivo.",
  'Search and channel history cleared.':
      "Historial de búsqueda y canales borrado.",
  'Clear Movies & TV Shows history?':
      "¿Borrar el historial de películas y series?",
  'Removes Continue Watching and the saved progress of every movie and episode.':
      "Elimina Seguir viendo y el progreso guardado de cada película y episodio.",
  'Movies & TV Shows history cleared.':
      "Historial de películas y series borrado.",
  'Language': "Idioma",
  'Follows the device language': "Usa el idioma del dispositivo",
  'Automatic': "Automático",
  'Startup': "Inicio",
  'Resume last channel in full screen':
      "Reanudar el último canal en pantalla completa",
  'Opens the last live channel full screen after the splash.':
      "Abre el último canal en vivo en pantalla completa tras la pantalla de inicio.",
  'Resume last channel with the guide open':
      "Reanudar el último canal con la guía abierta",
  'Plays the last live channel in the small preview, with the channel list.':
      "Reproduce el último canal en vivo en la vista previa pequeña, con la lista de canales.",
  'Both off: nothing plays at startup (a "Hold > to resume" reminder instead).':
      "Ambos desactivados: no se reproduce nada al iniciar (un aviso «Mantén > para reanudar» en su lugar).",
  'Tabs': "Pestañas",
  'Hide Movies and TV Shows': "Ocultar Películas y Series",
  'Removes both tabs and their search results, e.g. if you watch movies and shows elsewhere.':
      "Quita ambas pestañas y sus resultados de búsqueda, p. ej. si ves películas y series en otro lugar.",
  'Favorite channels are in the TV tab, under Favourites.':
      "Los canales favoritos están en la pestaña TV, en Favoritos.",
  'Show the Multiview tip': "Mostrar el consejo de Multivista",
  'The connections reminder shown when opening Multiview.':
      "El aviso sobre conexiones al abrir la Multivista.",
  'Resume reminder': "Aviso para reanudar",
  'Show the "Hold > to resume" reminder':
      "Mostrar el aviso «Mantén > para reanudar»",
  'The pill at the bottom while a channel plays in the background. Off: hidden.':
      "La píldora de abajo mientras un canal suena en segundo plano. Desactivado: oculta.",
  'The pill at the bottom while a channel plays in the background. Off: hidden — holding Right still resumes.':
      "La píldora de abajo mientras un canal suena en segundo plano. Desactivado: oculta; mantener Derecha sigue reanudando.",
  'Clear search & channel history': "Borrar historial de búsqueda y canales",
  'Recent searches and the live channel History':
      "Búsquedas recientes e historial de canales en vivo",
  'Clear Movies & TV Shows history': "Borrar historial de películas y series",
  'Continue Watching and saved progress': "«Seguir viendo» y progreso guardado",

  // ── Group management / hidden channels ───────────────────────────────
  'Leave group selection?': "¿Salir de la selección de grupos?",
  'Your show/hide choices are saved, and anything still visible will start downloading — same as pressing Done.':
      "Tus elecciones de mostrar/ocultar se guardan y todo lo visible empezará a descargarse, igual que al pulsar Listo.",
  'Leave': "Salir",
  'Save playlist?': "¿Guardar la lista?",
  'Your playlist will be saved with the selected groups. You can always add or remove groups later in Settings > Group Management.':
      "Tu lista se guardará con los grupos elegidos. Siempre puedes añadir o quitar grupos después en Ajustes > Gestión de grupos.",
  'Confirm': "Confirmar",
  'Group Management': "Gestión de grupos",
  'Done': "Listo",
  'If you are done selecting your groups, press Confirm below.\n\nIf you are not done yet, press Left to go back to your categories.':
      "Si terminaste de elegir tus grupos, pulsa Confirmar abajo.\n\nSi aún no, pulsa Izquierda para volver a tus categorías.",
  'No categories yet — load a playlist first.':
      "Aún no hay categorías; primero carga una lista.",
  'Search groups (starts with)': 'Buscar grupos (empieza por)',
  '{shown} of {total} groups': '{shown} de {total} grupos',
  'Show results': 'Mostrar resultados',
  'Hide results': 'Ocultar resultados',
  'No groups start with "{query}".': 'Ningún grupo empieza por «{query}».',
  'Show All': "Mostrar todo",
  'Hide All': "Ocultar todo",
  'Hidden channels': "Canales ocultos",
  'No channels are individually hidden. Hide one from its row in the Live TV list.':
      "No hay canales ocultos individualmente. Oculta uno desde su fila en la lista de TV en vivo.",
  'Unhide': "Mostrar",
  'Show group': "Mostrar grupo",
  'Hide group': "Ocultar grupo",

  // ── Playlist manager / priority ──────────────────────────────────────
  'Playlist Manager': "Gestor de listas",
  'Playlist Priority': "Prioridad de listas",
  'Which playlist\'s groups show first, per tab':
      "Qué lista muestra sus grupos primero, por pestaña",
  'No playlists yet — tap "Add Playlist" above to get started.':
      "Aún no hay listas: pulsa «Añadir lista» arriba para empezar.",
  'Delete playlist?': "¿Eliminar la lista?",
  'This removes "{name}"\'s login and cached catalog from this device. Its favorited channels/movies stay in your shared Favorites list, but will no longer play unless you add this playlist back.':
      "Esto elimina de este dispositivo la cuenta y el catálogo en caché de «{name}». Sus canales y películas favoritos siguen en tus Favoritos, pero no se reproducirán hasta que vuelvas a añadir esta lista.",
  'Delete': "Eliminar",
  'Add backup server': "Añadir servidor de respaldo",
  'The full address, exactly like the main one — for example http://backup.example.com:8080':
      "La dirección completa, igual que la principal; por ejemplo http://backup.example.com:8080",
  'Server address': "Dirección del servidor",
  'Add': "Añadir",
  'Edit login': "Editar cuenta",
  'Delete playlist': "Eliminar lista",
  'This Playlist': "Esta lista",
  'Playlist enabled': "Lista activada",
  'Frees up this account\'s stream slot for another device — stops playback here immediately, keeps everything else intact.':
      "Libera la conexión de esta cuenta para otro dispositivo: detiene la reproducción aquí al instante y conserva todo lo demás.",
  'Login Details': "Datos de la cuenta",
  'Server': "Servidor",
  'Expires': "Caduca",
  'Max connections': "Conexiones máx.",
  'Backup Servers': "Servidores de respaldo",
  'None yet. If your provider gave you more than one server address for this same account, add them here and this playlist will try them in order whenever the main one can\'t be reached.':
      "Ninguno todavía. Si tu proveedor te dio más de una dirección de servidor para esta misma cuenta, añádelas aquí y la lista las probará en orden cuando la principal no responda.",
  'Same username and password as above — only the address differs. Tried in order, a few seconds apart, and whichever answers is used first next time.':
      "Mismo usuario y contraseña que arriba; solo cambia la dirección. Se prueban en orden, con unos segundos entre cada uno, y el que responda se usa primero la próxima vez.",
  'Content Overview': "Resumen del contenido",
  'Not loaded yet.': "Aún no cargado.",
  '{p} live channels · {p2} movie categories · {p3} TV show categories':
      "{p} canales en vivo · {p2} categorías de películas · {p3} categorías de series",
  '{p} live · {p2} movies · {p3} TV shows':
      "{p} en vivo · {p2} películas · {p3} series",
  'Last updated: {p}': "Última act.: {p}",
  'Added: {p}': "Añadida: {p}",
  'Hidden Channels': "Canales ocultos",
  'Hide a group here and it\'s excluded from the background download too, not just the browse tabs.':
      "Un grupo oculto aquí también se excluye de la descarga en segundo plano, no solo de las pestañas.",
  'Full Catalog Sync': "Sincronización completa del catálogo",
  'Update content every': "Actualizar contenido cada",
  '1 day': "1 día",
  '{d} days': "{d} días",
  'A stale sync prompts "Update content now?" on launch instead of running automatically.':
      "Una sincronización antigua muestra «¿Actualizar el contenido ahora?» al iniciar, en vez de hacerse sola.",
  'in use': "en uso",
  'Remove {server}': "Quitar {server}",
  'Which playlist\'s groups show first — set independently for each tab below.':
      "Qué lista muestra sus grupos primero; se ajusta por separado para cada pestaña de abajo.",
  'Add another enabled playlist to set a priority between them.':
      "Añade otra lista activada para fijar una prioridad entre ellas.",
  'Live TV order': "Orden de TV en vivo",
  'Movies order': "Orden de películas",
  'TV Shows order': "Orden de series",
  'Move up': "Subir",
  'Move down': "Bajar",
  'Playlist added': "Lista añadida",
  'This playlist is disabled on this device — enable it in Settings > Playlist Manager to watch.':
      "Esta lista está desactivada en este dispositivo: actívala en Ajustes > Gestor de listas para ver.",

  // ── Profiles / PIN ───────────────────────────────────────────────────
  'Profiles': "Perfiles",
  'Add Profile': "Añadir perfil",
  'Rename profile': "Renombrar perfil",
  'Delete "{name}"?': "¿Eliminar «{name}»?",
  'Their favorites, hidden groups, and watch history are deleted too. This can\'t be undone.':
      "También se eliminan sus favoritos, grupos ocultos e historial. No se puede deshacer.",
  'Switch to another profile before deleting this one':
      "Cambia a otro perfil antes de eliminar este",
  'Delete profile': "Eliminar perfil",
  'This is the active profile': "Este es el perfil activo",
  'Switch to this profile': "Cambiar a este perfil",
  'Rename': "Renombrar",
  'What this profile can see': "Lo que puede ver este perfil",
  'Groups — {name}': "Grupos — {name}",
  'Hidden channels — {name}': "Canales ocultos — {name}",
  'For a child — hides every group, including adult content, by default. A parent unhides specific categories per playlist afterward in Group Management. A PIN is required to switch away from this profile or to open Settings while it\'s active.':
      "Para un niño: oculta todos los grupos por defecto, incluido el contenido para adultos. Después, un adulto muestra categorías concretas por lista en Gestión de grupos. Se necesita un PIN para salir de este perfil o abrir Ajustes mientras esté activo.",
  'Create': "Crear",
  'Incorrect PIN': "PIN incorrecto",
  "PINs didn't match — try again": "Los PIN no coinciden; inténtalo de nuevo",
  'Enter PIN': "Escribe el PIN",
  'Confirm PIN': "Confirma el PIN",
  'Set a PIN': "Elige un PIN",
  'Too many attempts — try again in {p}s':
      "Demasiados intentos; inténtalo de nuevo en {p} s",

  // ── Settings menu ────────────────────────────────────────────────────
  'M3U URL or Xtream Codes login': "URL M3U o cuenta Xtream Codes",
  'Every playlist: login, groups, enable/disable':
      "Todas las listas: cuenta, grupos, activar/desactivar",
  'Separate favorites, history & hidden groups per viewer':
      "Favoritos, historial y grupos ocultos separados por persona",
  'Language and history': "Idioma e historial",
  'Language, startup, Multiview and history':
      "Idioma, inicio, Multivista e historial",
  'Theme': "Tema",
  'Clock, accent color, layout': "Reloj, color, diseño",
  'Auto-refresh, channel matching & pairing, clear cache':
      "Act. automática, asociación y emparejado de canales, borrar caché",
  'TMDB (Release Dates)': "TMDB (fechas de estreno)",
  'Optional key for sorting by real release date':
      "Clave opcional para ordenar por fecha de estreno real",
  'Download and install the latest release':
      "Descargar e instalar la última versión",
  'Version —': "Versión —",
  'Version {version}': "Versión {version}",
  'Report any bugs or glitches to noxqcx@gmail.com':
      "Informa de errores o fallos a noxqcx@gmail.com",

  // ── Theme ────────────────────────────────────────────────────────────
  'Show clock': "Mostrar reloj",
  'Displays the current time in the top bar':
      "Muestra la hora en la barra superior",
  'Theme color': "Color del tema",
  'Auto picks phone vs TV layout by screen size — force one if your box isn\'t detected correctly.':
      "«Auto» elige el diseño de teléfono o TV según la pantalla; fuerza uno si tu equipo no se detecta bien.",
  'Live TV guide': "Guía de TV en vivo",
  'Timeline shows every channel at once, on a scrollable schedule grid, instead of one channel\'s now/next at a time.':
      "«Parrilla» muestra todos los canales a la vez en una cuadrícula desplazable, en lugar del ahora/después de un solo canal.",
  'Full-screen video behind the guide':
      "Vídeo a pantalla completa detrás de la guía",
  'The live channel fills the screen behind a see-through guide showing 3 rows':
      "El canal en directo llena la pantalla detrás de una guía transparente de 3 filas",
  'Auto': "Auto",
  'Phone': "Teléfono",
  'Timeline': "Parrilla",
  'Platinum': "Platino",
  'Rosé': "Rosé",
  'Neon Purple': "Morado neón",
  'Neon Green': "Verde neón",
  'Aqua': "Aguamarina",
  'Red': "Rojo",
  'Blue': "Azul",
  'Dark / Gold': "Negro / Oro",

  // ── TMDB ─────────────────────────────────────────────────────────────
  'Cleared — TMDB sorting is now off':
      "Borrada: el orden por TMDB está desactivado",
  'Saved — key verified with TMDB ✓': "Guardada: clave verificada con TMDB ✓",
  'Saved, but TMDB rejected this key — double-check it\'s correct':
      "Guardada, pero TMDB rechazó esta clave; revisa que sea correcta",
  'What\'s New refreshed from TMDB': "Novedades actualizadas desde TMDB",
  'TMDB (The Movie Database) is a free, independent movie and TV database — not your IPTV provider. Adding your own free TMDB key lets VesperTV look up a title\'s actual real-world release date, which powers two things: a "TMDB" sort option on any group\'s "Expand catalog" screen, and a more accurate "What\'s New" row (ordered by real release date instead of just when your provider added the title).':
      "TMDB (The Movie Database) es una base de datos de películas y series gratuita e independiente; no es tu proveedor IPTV. Con tu propia clave gratuita de TMDB, VesperTV consulta la fecha de estreno real de un título, lo que sirve para dos cosas: una opción de orden «TMDB» en la pantalla «Catálogo completo» de cada grupo, y una fila de «Novedades» más precisa (ordenada por fecha de estreno real en vez de por cuándo la añadió tu proveedor).",
  'This is completely optional and free — VesperTV works 100% without it. Without a key, sorting just falls back to whenever your provider added or updated each title, which is still available and works fine on its own.':
      "Es totalmente opcional y gratis: VesperTV funciona al 100 % sin ella. Sin clave, el orden usa la fecha en que tu proveedor añadió o actualizó cada título, que también funciona bien.",
  'To get one: create a free account at themoviedb.org, then generate an API key under Settings > API (choose "Personal use" when asked) and paste it below. VesperTV never collects or shares it — it\'s stored only on this device.':
      "Para obtenerla: crea una cuenta gratis en themoviedb.org, genera una clave API en Settings > API (elige «Personal use» cuando te lo pida) y pégala abajo. VesperTV nunca la recopila ni la comparte; solo se guarda en este dispositivo.",
  'TMDB API Key': "Clave API de TMDB",
  'What\'s New only re-checks TMDB about once a week on its own. Use this to force it right now instead of waiting — useful right after saving a key for the first time.':
      "Novedades solo vuelve a consultar TMDB más o menos una vez por semana. Usa esto para forzarlo ahora mismo; útil justo después de guardar una clave por primera vez.",
  'Refresh What\'s New Now': "Actualizar Novedades ahora",
  'This product uses the TMDB API but is not endorsed or certified by TMDB.':
      "Este producto usa la API de TMDB, pero no está respaldado ni certificado por TMDB.",

  // ── Loading phases / connection ──────────────────────────────────────
  'No Title': "Sin título",
  'Reconnecting...': "Reconectando…",
  'Trying to reconnect on backup servers ({p}/{candidates})...':
      "Intentando reconectar en servidores de respaldo ({p}/{candidates})…",
  'Finding live channels... ({p} found)':
      "Buscando canales en vivo… ({p} encontrados)",
  'Finding movies... ({p} found)': "Buscando películas… ({p} encontradas)",
  'Finding TV shows... ({p} found)': "Buscando series… ({p} encontradas)",
  'Connecting to {label} ({p}/{candidates})...':
      "Conectando a {label} ({p}/{candidates})…",
  'Connected to {label}': "Conectado a {label}",
  'Connecting to {label} ({p}/{candidates})... failed':
      "Conectando a {label} ({p}/{candidates})… error",
  'Finding live channels...': "Buscando canales en vivo…",
  'Finding live channels... ({loadedLive} found)':
      "Buscando canales en vivo… ({loadedLive} encontrados)",
  'Finding movie categories...': "Buscando categorías de películas…",
  'Finding movies... ({vodCategories} categories found)':
      "Buscando películas… ({vodCategories} categorías encontradas)",
  'Finding TV show categories...': "Buscando categorías de series…",
  'Finding TV shows... ({seriesCategories} categories found)':
      "Buscando series… ({seriesCategories} categorías encontradas)",
  'Loading full catalog in the background — {p}':
      "Cargando el catálogo completo en segundo plano — {p}",
  'Ready': "Listo",
  '{done}/{total} categories': "{done}/{total} categorías",

  'Failed to load EPG (HTTP {code})': "No se pudo cargar la guía (HTTP {code})",
  'Failed to load playlist from {host} (HTTP {code})':
      "No se pudo cargar la lista desde {host} (HTTP {code})",
  'Xtream request to {server} failed: {action} (HTTP {code})':
      "Falló la solicitud Xtream a {server}: {action} (HTTP {code})",
  'Main': "Principal",
  '{h}h ': "{h} h ",

  // ── Small widgets ────────────────────────────────────────────────────
  'Unpin': "Quitar de favoritos",
  'Pin as favorite': "Fijar como favorito",
  'Next: {p}': "Después: {p}",
  'NOW: {title} ({p}-{p2})': "AHORA: {title} ({p}-{p2})",
  'NEXT: {title} ({p})': "DESPUÉS: {title} ({p})",
  'Hold ': "Mantén ",
  ' to resume': " para reanudar",
  'Expand sidebar': "Expandir panel",
  'Collapse sidebar': "Contraer panel",
  'Pinned channels': "Canales fijados",
  'League manager': "Gestor de ligas",
  'Your leagues': "Tus ligas",
  'League bank': "Banco de ligas",
  'Every league is added.': "Todas las ligas están añadidas.",
  'Added · hold to send back': "Añadida · mantén para devolverla",
  '{name} is back in the league bank': "{name} volvió al banco de ligas",
  'England': "Inglaterra",
  'Spain': "España",
  'Germany': "Alemania",
  'Italy': "Italia",
  'France': "Francia",
  'Europe': "Europa",
  'Cups': "Copas",
  'Americas': "Américas",
  'World': "Mundo",
  'Women': "Femenino",
  'Basketball': "Baloncesto",
  'Hockey': "Hockey",
  'Baseball': "Béisbol",
  'Other': "Otros",
  'Golf': "Golf",
  'Tennis': "Tenis",
  'Rugby': "Rugby",
  'Cricket': "Críquet",
  'Darts': "Dardos",
  'Fighting': "Combate",
  'Motorsport': "Motor",
  'Always for {name}': "Siempre para {name}",
  'Best for a channel that carries the whole series':
      "Ideal para un canal que emite toda la serie",
  'Next game: {date}': "Próximo partido: {date}",
  'No upcoming games listed yet for this league.':
      "Todavía no hay próximos partidos para esta liga.",
  'Transfer to another device': "Transferir a otro dispositivo",
  'Copy all of your data to another device':
      "Copia todos tus datos a otro dispositivo",
  'Copies your playlists, favorites, hidden groups, profiles, watch progress, {tab} (leagues, favourite league, My Teams) and settings to another device. On the same Wi-Fi it goes straight across; anywhere else it goes through an encrypted upload only the code can open. Channels, movies and the guide download again on the new device.':
      "Copia tus listas, favoritos, grupos ocultos, perfiles, progreso, {tab} (ligas, liga favorita, Mis equipos) y ajustes a otro dispositivo. En el mismo Wi-Fi pasa directamente; desde otro lugar pasa por una subida cifrada que solo el código puede abrir. Los canales, películas y la guía se vuelven a descargar en el nuevo dispositivo.",
  'This setup is too big to upload. Use the same-Wi-Fi transfer instead.':
      "Esta configuración es demasiado grande para subirla. Usa la transferencia por el mismo Wi-Fi.",
  'Couldn\'t reach the VesperTV transfer server. Check this device\'s internet connection and try again.':
      "No se pudo contactar con el servidor de transferencia de VesperTV. Revisa la conexión a internet de este dispositivo y vuelve a intentarlo.",
  '{n} hour': "{n} hora",
  '{n} hours': "{n} horas",
  '{n} day': "{n} día",
  '{n} days': "{n} días",
  'Your setup is encrypted on this device and uploaded. Any device that enters the code can copy it until it expires — even with this device turned off. How long should it stay available?':
      "Tu configuración se cifra en este dispositivo y se sube. Cualquier dispositivo que escriba el código puede copiarla hasta que caduque, incluso con este dispositivo apagado. ¿Cuánto tiempo debe estar disponible?",
  'Encrypting and uploading…': "Cifrando y subiendo…",
  'Works on any network until {time}':
      "Funciona en cualquier red hasta: {time}",
  'Anyone with this code can copy your setup, playlist logins included. Changes made after this upload aren\'t in it — upload again to update it.':
      "Cualquiera con este código puede copiar tu configuración, incluidos los accesos de las listas. Los cambios posteriores a esta subida no están incluidos: vuelve a subirla para actualizarla.",
  'Upload again': "Volver a subir",
  'Delete now': "Eliminar ahora",
  'Nothing was found for that code. Check it — the upload may also have expired or been deleted.':
      "No se encontró nada con ese código. Revísalo; la subida también puede haber caducado o haberse eliminado.",
  '9 digits on the same Wi-Fi, 16 digits over the internet':
      "9 dígitos en el mismo Wi-Fi, 16 por internet",
  '24-hour clock': "Reloj de 24 horas",
  'Times show as 21:30': "Las horas se muestran así: 21:30",
  'Times show as 9:30 PM': "Las horas se muestran así: 9:30 PM",
  'Welcome back, legend': "Bienvenido de nuevo, leyenda",
  'No favourites yet. Hold Select on a poster or a group to add one.':
      "Todavía no hay favoritos. Mantén OK sobre un póster o un grupo para añadir uno.",
  'Rotate': "Girar",
  'You have great taste': "Tienes un gusto excelente",
  'Looking sharp today': "Hoy te ves increíble",
  'You make this place better': "Haces de este lugar algo mejor",
  'Hey superstar': "Hola, superestrella",
  'You deserve this break': "Te mereces este descanso",
  'You\'re doing amazing': "Lo estás haciendo genial",
  'Hello, wonderful you': "Hola, persona maravillosa",
  'Smart choice, as always': "Buena elección, como siempre",
  'You light up the room': "Iluminas la habitación",
  'Keep shining, you\'ve got this': "Sigue brillando, tú puedes",
  'You earned some fun today': "Hoy te ganaste un poco de diversión",
  'The world is better with you in it': "El mundo es mejor contigo",
  'Hey champ, welcome in': "Hola, campeón, adelante",
  'Send from this device': "Enviar desde este dispositivo",
  'Shows a code to enter on the other device':
      "Muestra un código para escribir en el otro dispositivo",
  'Both devices on the same Wi-Fi?': "¿Los dos dispositivos en el mismo Wi-Fi?",
  'Send directly, without uploading': "Enviar directamente, sin subir nada",
  'Receive on this device': "Recibir en este dispositivo",
  'Replaces this device\'s setup with the other one\'s':
      "Reemplaza la configuración de este dispositivo por la del otro",
  'This device isn\'t on a Wi-Fi or wired home network.':
      "Este dispositivo no está en una red Wi-Fi o por cable.",
  'Sent! Finish on the other device.':
      "¡Enviado! Termina en el otro dispositivo.",
  'This code has expired. Go back and start again.':
      "Este código caducó. Vuelve atrás y empieza de nuevo.",
  'On the other device, open Settings > Transfer to another device > Receive, and enter:':
      "En el otro dispositivo, abre Ajustes > Transferir a otro dispositivo > Recibir y escribe:",
  'This device: {address} · the code works once, for 10 minutes':
      "Este dispositivo: {address} · el código sirve una vez, durante 10 minutos",
  'Couldn\'t find the other device. Check the code, and that both devices are on the same Wi-Fi with the code still showing.':
      "No se encontró el otro dispositivo. Revisa el código y que ambos estén en el mismo Wi-Fi con el código todavía en pantalla.",
  'That code isn\'t right. Check it on the other device.':
      "Ese código no es correcto. Revísalo en el otro dispositivo.",
  'That code has expired or was already used. Start again on the other device.':
      "Ese código caducó o ya se usó. Empieza de nuevo en el otro dispositivo.",
  'The transfer didn\'t go through. Try again.':
      "La transferencia no se completó. Inténtalo de nuevo.",
  'Transfer complete': "Transferencia completa",
  'VesperTV will close now. Open it again to load your playlists.':
      "VesperTV se cerrará ahora. Ábrelo de nuevo para cargar tus listas.",
  'Enter the code shown on the other device':
      "Escribe el código que aparece en el otro dispositivo",
  'Ready to copy': "Listo para copiar",
  '{playlists} playlists · {profiles} profiles · {favorites} favorites':
      "Listas: {playlists} · Perfiles: {profiles} · Favoritos: {favorites}",
  'This replaces the playlists, favorites and settings on this device.':
      "Esto reemplaza las listas, favoritos y ajustes de este dispositivo.",
  'Replace my data': "Reemplazar mis datos",
  'Enter the address shown under the code on the other device (This device: …)':
      "Escribe la dirección que aparece bajo el código en el otro dispositivo (Este dispositivo: …)",
  'Code: {code}': "Código: {code}",
  'Type the address instead': "Escribir la dirección",
  '{n} playlist': "{n} lista",
  '{n} playlists': "{n} listas",
  '{n} profile': "{n} perfil",
  '{n} profiles': "{n} perfiles",
  '{n} favorite': "{n} favorito",
  '{n} favorites': "{n} favoritos",
  'Clear favourites?': "¿Borrar favoritos?",
  "Removes every starred item and favourite group from this tab's Favourites.":
      "Quita todos los elementos marcados y grupos favoritos de los Favoritos de esta pestaña.",
  'Favourites cleared.': "Favoritos borrados.",
  'Delete watched history?': "¿Eliminar el historial de visualización?",
  'Removes the History list of live channels.':
      "Borra la lista Historial de canales en directo.",
  'Watched history deleted.': "Historial de visualización eliminado.",
  'NFL RedZone channel': "Canal NFL RedZone",
  // Series detail screen
  'Resume {code}': "Reanudar {code}",
  'Play {code}': "Reproducir {code}",
  '{n} seasons': "{n} temporadas",
  '{n} episodes': "{n} episodios",
  '1 episode': "1 episodio",
  '{m} min': "{m} min",
  '{h} h {m} min': "{h} h {m} min",
  'Episode {n}': "Episodio {n}",
  'Watched': "Visto",
  'More': "Más",
  'Watching': "Viendo",
  'Marked as watched': "Marcado como visto",
  'Marked as unwatched': "Marcado como no visto",
  'Hold to mark as watched': "Mantén pulsado para marcar como visto",
  'Hold to mark as unwatched': "Mantén pulsado para marcar como no visto",
  'Cast: {names}': "Reparto: {names}",
  'Director: {names}': "Dirección: {names}",
  'Specials': "Especiales",
  'Movie and TV artwork and data may come from TMDB (The Movie Database).':
      "Las imágenes y los datos de películas y series pueden provenir de TMDB (The Movie Database).",
  '{appName} {version} is available': "{appName} {version} está disponible",
  "What's new:": "Novedades:",
  'A new version is ready to install.':
      "Hay una nueva versión lista para instalar.",
  'Skip this version': "Omitir esta versión",
  'Later': "Más tarde",
  'See all · stats': "Ver todo · estadísticas",
  'Live games': "Partidos en vivo",
  'Click a game for its stats':
      "Haz clic en un partido para ver sus estadísticas",
  'No games are live right now': "No hay partidos en vivo ahora",
  'RED ZONE': "ZONA ROJA",
  'No channel': "Sin canal",
  'Watch on {channel}': "Ver en {channel}",
  'No channel found. Hold OK on the game in {tab} to pick one.':
      "No se encontró canal. Mantén OK sobre el partido en {tab} para elegir uno.",
  '▲▼ scroll · Back closes': "▲▼ desplazar · Atrás cierra",
  'Passing': "Pases",
  'Rushing': "Carrera",
  'Receiving': "Recepción",
  'Defense': "Defensa",
  'Kicking': "Pateo",
  'Forwards': "Delanteros",
  'Defensemen': "Defensas",
  'Goalies': "Porteros",
  'Batting': "Bateo",
  'Pitching': "Pitcheo",
  'Players': "Jugadores",
  'No stats for this game yet.': "Aún no hay estadísticas de este partido.",
  'Top performers': "Mejores jugadores",
  'Injuries': "Lesiones",
  'Goals': "Goles",
  'pen.': "pen.",
  'Team stats': "Estadísticas de equipo",
  'OK = stats · hold OK = channels · ▶❚❚ = watch':
      "OK = estadísticas · mantener OK = canales · ▶❚❚ = ver",
  '{channel} · full screen': "{channel} · pantalla completa",
  // ── Archive tab ──────────────────────────────────────────────────────
  "Add a source": "Añadir una fuente",
  "Couldn't load the catalog: {error}":
      "No se pudo cargar el catálogo: {error}",
  "Couldn't reach that link.": "No se pudo acceder a ese enlace.",
  "This link failed at the provider. Choose another stream.":
      "Este enlace falló en el proveedor. Elige otro stream.",
  "Menu": "Menú",
  "No playable stream for this title.":
      "No hay ningún stream reproducible para este título.",
  "No sources yet.": "Todavía no hay fuentes.",
  "None of your sources has TV shows.": "Ninguna de tus fuentes tiene series.",
  "None of your sources has movies.": "Ninguna de tus fuentes tiene películas.",
  "Nothing here yet.": "Aún no hay nada aquí.",
  "Refresh": "Actualizar",
  "Source link (ends with manifest.json)":
      "Enlace de la fuente (termina en manifest.json)",
  "That source is already in the list.": "Esa fuente ya está en la lista.",
  "This source lists no episodes for this show.":
      "Esta fuente no muestra episodios para esta serie.",
  "VesperTV ships no sources. The titles you open are requested from the source you added; nothing else is shared.":
      "VesperTV no incluye fuentes. Los títulos que abres se piden a la fuente que añadiste; no se comparte nada más.",
  "Your sources": "Tus fuentes",
  "{n} TV show catalogs": "{n} catálogos de series",
  "{n} movie catalogs": "{n} catálogos de películas",
  "Check the link here, then press Add.":
      "Revisa el enlace aquí y pulsa Añadir.",
  "Hide Movies": "Ocultar Películas",
  "Hide TV Shows": "Ocultar Series",
  "Hide Recordings": "Ocultar grabaciones",
  "Typing a key with a remote is painful. Scan this code with your phone camera and paste the key there — it appears here for you to check and save.":
      "Escribir una clave con un mando es tedioso. Escanea este código con la cámara del teléfono y pega allí la clave: aparecerá aquí para que la revises y la guardes.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and save.":
      "Escribir un enlace largo con un mando es tedioso. Escanea este código con la cámara del teléfono y pega allí el enlace: aparecerá aquí para que lo revises y lo guardes.",
  "Paste the key and tap Send to TV.": "Pega la clave y toca Enviar a la TV.",
  "Check it here, then press Save.": "Revísalo aquí y pulsa Guardar.",
  "Paste the link and tap Send to TV.": "Pega el enlace y toca Enviar a la TV.",
  "Removes the Movies tab and movie search results.":
      "Quita la pestaña Películas y las películas de la búsqueda.",
  "Removes the TV Shows tab and show search results.":
      "Quita la pestaña Series y las series de la búsqueda.",
  "Removes the Recordings tab.": "Quita la pestaña Grabaciones.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and add.":
      "Escribir un enlace largo con el mando es un suplicio. Escanea este código con la cámara del móvil y pega ahí el enlace — aparecerá aquí para que lo revises y lo añadas.",
  // Archive: rows, search, stream picker
  'Popular': 'Populares',
  'New': 'Novedades',
  'Featured': 'Destacados',
  'Search movies': 'Buscar películas',
  'Search TV shows': 'Buscar series',
  'Title': 'Título',
  'Searching…': 'Buscando…',
  'Clear search': 'Borrar búsqueda',
  'Results for "{query}"': 'Resultados para «{query}»',
  'No results for "{query}"': 'Sin resultados para «{query}»',
  'Choose a stream': 'Elegir una fuente',
  'Stream {n}': 'Fuente {n}',
  // Transfer: Archive tab data
  // Media Hub tab (was Extras, before that Archive) + Multiview toggle
  // Trakt & Simkl (trackers_screen.dart, tracker rows)
  'Watch tracking powered by Trakt and Simkl; VesperTV is not affiliated with or endorsed by either.':
      "Seguimiento de lo que ves con Trakt y Simkl; VesperTV no está afiliado ni respaldado por ninguno de los dos.",
  'Powered by Trakt (trakt.tv) and Simkl (simkl.com).':
      "Con la tecnología de Trakt (trakt.tv) y Simkl (simkl.com).",
  'VesperTV is not affiliated with or endorsed by Trakt or Simkl.':
      "VesperTV no está afiliado ni respaldado por Trakt o Simkl.",
  'Trakt & Simkl': 'Trakt y Simkl',
  'Track what you watch, lists in the Media Hub':
      'Registra lo que ves, listas en el Media Hub',
  'Connected as {name} — press OK to disconnect':
      'Conectado como {name} — pulsa OK para desconectar',
  'Not available in this build yet': 'Aún no disponible en esta versión',
  'Connect a watch tracker: what you watch in the Media Hub is marked as watched on your account, and your lists show up as Media Hub rows. Nothing is sent unless you connect an account.':
      'Conecta un servicio de seguimiento: lo que ves en el Media Hub se marca como visto en tu cuenta y tus listas aparecen como filas en el Media Hub. No se envía nada si no conectas una cuenta.',
  'Watchlist and trending rows, scrobbling':
      'Filas de watchlist y tendencias, scrobbling',
  'Watching and plan-to-watch rows, scrobbling':
      'Filas viendo y por ver, scrobbling',
  'Titles from your lists play through your stream add-ons (Media Hub sources), by IMDb id. Only titles with an IMDb id are reported.':
      'Los títulos de tus listas se reproducen con tus complementos de flujo (fuentes del Media Hub), por id de IMDb. Solo se informan los títulos con id de IMDb.',
  '{name} connected.': '{name} conectado.',
  'Disconnect {name}?': '¿Desconectar {name}?',
  'Its rows leave the Media Hub and plays are no longer reported. Your account itself is untouched.':
      'Sus filas salen del Media Hub y las reproducciones ya no se informan. Tu cuenta no se modifica.',
  'Disconnect': 'Desconectar',
  'Couldn\'t reach {name}. Check the connection.':
      'No se pudo conectar con {name}. Revisa la conexión.',
  'The code expired. Try again.': 'El código caducó. Inténtalo de nuevo.',
  'Sign-in was not completed. Try again.':
      'No se completó el inicio de sesión. Inténtalo de nuevo.',
  'Connect {name}': 'Conectar {name}',
  'On your phone or computer, open': 'En tu teléfono u ordenador, abre',
  'and enter this code:': 'e introduce este código:',
  'Waiting for you to approve…': 'Esperando tu aprobación…',
  'Try again': 'Reintentar',
  'Trakt watchlist': 'Watchlist de Trakt',
  'Trending on Trakt': 'Tendencias en Trakt',
  'Watching on Simkl': 'Viendo en Simkl',
  'Simkl plan to watch': 'Por ver en Simkl',
  // Multiview picker: Live now / Sports shortcuts
  '{n} channels': '{n} canales',
  'No live games on your channels right now':
      'Ningún partido en directo en tus canales ahora mismo',
  // Media Hub: Connect Jellyfin / Emby (media_server_screen.dart)
  'Connect Jellyfin / Emby': 'Conectar Jellyfin / Emby',
  'User name': 'Nombre de usuario',
  'Connect': 'Conectar',
  'Enter the server address and your user name.':
      'Introduce la dirección del servidor y tu nombre de usuario.',
  'Wrong user name or password.': 'Nombre de usuario o contraseña incorrectos.',
  'This account has no movie or TV library.':
      'Esta cuenta no tiene ninguna biblioteca de películas o series.',
  'Couldn\'t find a Jellyfin or Emby server at that address.':
      'No se encontró ningún servidor Jellyfin o Emby en esa dirección.',
  'Sign in to your own Jellyfin or Emby server: its movie and TV libraries show up in the Media Hub. Files play as they are stored on the server (no transcoding).':
      'Inicia sesión en tu propio servidor Jellyfin o Emby: sus bibliotecas de películas y series aparecen en el Media Hub. Los archivos se reproducen tal como están guardados en el servidor (sin transcodificación).',
  'Your password is only sent to your server. VesperTV keeps the sign-in token the server gives back, not the password.':
      'Tu contraseña solo se envía a tu servidor. VesperTV guarda el token de sesión que devuelve el servidor, no la contraseña.',
  'Media Hub': 'Media Hub',
  'Media Hub sources': 'Fuentes de Media Hub',
  'Add-on sources for the Media Hub tab':
      'Fuentes de complementos para la pestaña Media Hub',
  'Clear Media Hub?': '¿Borrar Media Hub?',
  'Clear Media Hub': 'Borrar Media Hub',
  'Media Hub cleared.': 'Media Hub borrado.',
  'Include Media Hub tab data': 'Incluir los datos de la pestaña Media Hub',
  'Media Hub sources and their watch progress are sent too':
      'También se envían las fuentes de Media Hub y su progreso',
  'The other device keeps its own Media Hub sources':
      'El otro dispositivo conserva sus propias fuentes de Media Hub',
  'Add a source to browse films and series. Any source that follows the catalog/stream add-on format works.':
      'Añade una fuente para explorar películas y series. Funciona cualquier fuente que siga el formato de complemento catálogo/flujo.',
  'That link isn\'t a Media Hub source (it needs movie or series streams).':
      'Ese enlace no es una fuente de Media Hub (necesita flujos de películas o series).',
  'Removes every Media Hub source and its saved catalog from this device.':
      'Quita todas las fuentes de Media Hub y su catálogo guardado de este dispositivo.',
  'The Media Hub tab shows films and series from sources you add here. Any source that follows the catalog/stream add-on format works; a source that only offers streams by IMDb id gets its posters and episodes from Cinemeta. Only direct video links are played; torrent links are ignored.':
      'La pestaña Media Hub muestra películas y series de las fuentes que añadas aquí. Funciona cualquier fuente que siga el formato de complemento catálogo/flujo; una fuente que solo ofrece flujos por id de IMDb toma sus carátulas y episodios de Cinemeta. Solo se reproducen enlaces de vídeo directos; los enlaces torrent se ignoran.',
  'Hide Media Hub': 'Ocultar Media Hub',
  'Removes the Media Hub tab.': 'Quita la pestaña Media Hub.',
  'Hide Multiview': 'Ocultar Multivista',
  'Removes the Multiview row and the player\'s Open in Multiview button.':
      'Quita la fila Multivista y el botón Abrir en Multivista del reproductor.',
  // Extras genre filter
  'Genre': 'Género',
  'All genres': 'Todos los géneros',
  'genre.Action': 'Acción',
  'genre.Adventure': 'Aventura',
  'genre.Animation': 'Animación',
  'genre.Biography': 'Biografía',
  'genre.Comedy': 'Comedia',
  'genre.Crime': 'Crimen',
  'genre.Documentary': 'Documental',
  'genre.Drama': 'Drama',
  'genre.Family': 'Familia',
  'genre.Fantasy': 'Fantasía',
  'genre.History': 'Historia',
  'genre.Horror': 'Terror',
  'genre.Mystery': 'Misterio',
  'genre.Romance': 'Romance',
  'genre.Sci-Fi': 'Ciencia ficción',
  'genre.Sport': 'Deporte',
  'genre.Thriller': 'Suspense',
  'genre.War': 'Bélica',
  'genre.Western': 'Western',
  'genre.Reality-TV': 'Telerrealidad',
  'genre.Talk-Show': 'Programa de entrevistas',
  'genre.Game-Show': 'Concurso',
  // Sports: favourite league
  'OK: show/hide or add · Hold OK: favourite league, or send an added league back to the bank':
      'OK: mostrar/ocultar o añadir · Mantén OK: liga favorita, o devolver una liga añadida al banco',
  'Make favourite league': 'Hacerla liga favorita',
  'Remove from favourite': 'Quitar de favorita',
  '{tab} opens on it and its games come first in Live now':
      '{tab} se abre en ella y sus partidos salen primero en En vivo',
  'Send back to the league bank': 'Devolver al banco de ligas',
  'Favourite league': 'Liga favorita',
  // Player side panel: Pull stats
  '◀ ▶ tabs  ·  OK to watch  ·  Hold OK for stats  ·  Back to close':
      '◀ ▶ pestañas  ·  OK para ver  ·  Mantén OK: estadísticas  ·  Atrás para cerrar',
  // Sports hero on Windows
  'Click the game again or Enter: full screen  ·  Esc: stop':
      'Haz clic otra vez en el partido o Intro: pantalla completa  ·  Esc: detener',
  'Click again: watch here  ·  Hold: pick the channel':
      'Clic otra vez: ver aquí  ·  Mantener: elegir el canal',
  // Extras floating Search / Genre bar
  'Movie genres': 'Géneros de películas',
  'TV show genres': 'Géneros de series',
  // Extras: watched history + recent searches
  'Recently watched': 'Vistos recientemente',
  'Clear recent searches': 'Borrar búsquedas recientes',
  // Data pool (player stream details, Settings > General)
  "Data pool": "Data pool",
  "Data pool display": "Mostrar el Data pool",
  "Press OK while a live channel plays to open a second card under the channel info with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Pulsa OK mientras se reproduce un canal en directo para abrir una segunda tarjeta bajo la información del canal con los detalles de la emisión: resolución, fotogramas por segundo, códecs, tasa de bits, variantes de calidad, pistas de audio, búfer y HDR. Desactivado: OK solo muestra la información del canal.",
  "Reading the stream…": "Leyendo la emisión…",
  "Video": "Vídeo",
  "Video bitrate": "Tasa de bits de vídeo",
  "Picture": "Imagen",
  "Quality variants": "Variantes de calidad",
  "One (not adaptive)": "Una (no adaptativa)",
  "Audio": "Audio",
  "Audio tracks": "Pistas de audio",
  "Stream": "Emisión",
  "Buffered": "En búfer",
  "{seconds} s": "{seconds} s",
  "State": "Estado",
  "Buffering…": "Cargando búfer…",
  "Playing for {time}": "Reproduciendo desde hace {time}",
  "Paused": "En pausa",
  "Device HDR": "HDR del dispositivo",
  "Not reported by the stream": "La emisión no lo indica",
  "Mono": "Mono",
  "Stereo": "Estéreo",
  "Direct stream": "Emisión directa",
  "Yes": "Sí",
  "No": "No",
  "Stream bitrate": "Tasa de bits de la emisión",
  "Declared bitrate": "Tasa de bits declarada",
  "Dropped frames": "Fotogramas perdidos",
  "(measured)": "(medido)",
  "Measuring…": "Midiendo…",
  // Settings categories (left panel)
  "Playlists & guide": "Listas y guía",
  "Your playlists and their logins, the TV guide (EPG) and the viewer profiles.":
      "Tus listas y sus accesos, la guía de TV (EPG) y los perfiles.",
  "Everything the Media Hub uses: its add-on sources, online subtitles, Trakt & Simkl watch tracking and the optional TMDB key.":
      "Todo lo que usa el Media Hub: sus fuentes de add-ons, subtítulos en línea, el seguimiento de Trakt y Simkl y la clave TMDB opcional.",
  "Interface": "Interfaz",
  "How the app looks and what it shows: theme, tabs, matching the TV's frame rate, the player's extras and reminders.":
      "Cómo se ve la app y qué muestra: tema, pestañas, ajustar la frecuencia de imagen del televisor, extras del reproductor y recordatorios.",
  "Hide Movies, TV Shows, Media Hub, Recordings or Multiview":
      "Ocultar Películas, Series, Media Hub, Grabaciones o Multiview",
  "Fixes for the picture on some Fire TV sticks":
      "Arreglos para la imagen en algunos Fire TV Stick",
  "Dolby Atmos to your soundbar or receiver":
      "Dolby Atmos a tu barra de sonido o receptor",
  "Surround passthrough (Dolby Atmos)":
      "Sonido envolvente directo (Dolby Atmos)",
  "Sends Dolby Digital, Dolby Atmos and DTS sound to your soundbar or receiver untouched (HDMI passthrough), so it can play Atmos. Off: this device turns that sound into plain stereo/5.1 first, so Atmos is lost. While on, the volume of that sound is set on your TV or receiver only, and if you hear nothing on a channel, turn this off. Multiview always uses plain sound (passthrough there kept muted screens playing). Applies from the next channel.":
      "Envía el sonido Dolby Digital, Dolby Atmos y DTS sin tocar a tu barra de sonido o receptor (passthrough HDMI), para que pueda reproducir Atmos. Desactivado: este dispositivo convierte antes ese sonido en estéreo/5.1 normal y se pierde el Atmos. Activado, el volumen de ese sonido se ajusta solo en tu TV o receptor, y si no oyes nada en un canal, desactívalo. Multiview siempre usa sonido normal (allí el passthrough dejaba sonar las pantallas silenciadas). Se aplica desde el siguiente canal.",
  "Stream details when you press OK on a channel":
      "Detalles del flujo al pulsar OK en un canal",
  "One list for every playlist, or one per playlist":
      "Una lista para todas las listas, o una por lista",
  "The connections tip when opening Multiview":
      "El aviso de conexiones al abrir Multiview",
  "The \"Hold > to resume\" pill": "La píldora «Mantén > para reanudar»",
  "Language and clock, what plays when the app starts, Fast startup, and clearing your history.":
      "Idioma y reloj, qué se reproduce al iniciar, Inicio rápido y borrar tu historial.",
  "App language and 24-hour clock": "Idioma de la app y reloj de 24 horas",
  "Resume the last channel, Fast startup":
      "Reanudar el último canal, Inicio rápido",
  "Clear searches, channels, Continue Watching":
      "Borrar búsquedas, canales, Seguir viendo",
  "Device & data": "Dispositivo y datos",
  "Move your whole setup to another device, keep a backup of it, and update VesperTV.":
      "Copia toda tu configuración a otro dispositivo, guarda una copia de seguridad y actualiza VesperTV.",
  // Own live groups (Move to group)
  "Move to group…": "Mover a un grupo…",
  "Move {name} to": "Mover {name} a",
  "New group…": "Nuevo grupo…",
  "Back to {group}": "Volver a {group}",
  "New group": "Nuevo grupo",
  "Group name": "Nombre del grupo",
  "{name} is now in {group}": "{name} ahora está en {group}",
  "Delete this group": "Eliminar este grupo",
  "{group} deleted. Its channels are back in their groups.":
      "{group} eliminado. Sus canales vuelven a sus grupos.",
  // Fast startup
  "Fast startup": "Inicio rápido",
  "Opens the app without waiting for Movies and TV Shows to load; they fill in a few seconds later. For fast devices — leave it off on an older box if the app closes by itself right after starting. Applies from the next start.":
      "Abre la app sin esperar a que carguen Películas y Series; se completan unos segundos después. Para dispositivos rápidos — déjalo desactivado en un aparato antiguo si la app se cierra sola justo después de iniciar. Se aplica en el próximo inicio.",
  // Group hold menu: New group
  "{group} created. Hold OK on a channel > Move to group… to add channels.":
      "{group} creado. Mantén OK en un canal > Mover a un grupo… para añadir canales.",
  // Channel menu: Remove from group
  "Remove from {group}": "Quitar de {group}",
  // Settings > Device & data > Send log
  "Send log": "Enviar registro",
  "Send the app's log to the developer":
      "Enviar el registro de la app al desarrollador",
  "Sending...": "Enviando...",
  "Send again": "Enviar de nuevo",
  "Log sent. Your code:": "Registro enviado. Tu código:",
  "Mention this code on Reddit or Discord with what happened, so the developer can find your log.":
      "Menciona este código en Reddit o Discord junto con lo que pasó, para que el desarrollador encuentre tu registro.",
  "Something not working? Send the app's log to the VesperTV developer. It holds what the app did recently (this session and the last one) and your device model, nothing else.":
      "¿Algo no funciona? Envía el registro de la app al desarrollador de VesperTV. Contiene lo que la app hizo recientemente (esta sesión y la anterior) y el modelo de tu dispositivo, nada más.",
  "Server addresses, user names, passwords and other private details are removed before sending.":
      "Las direcciones de servidor, nombres de usuario, contraseñas y otros datos privados se eliminan antes de enviar.",
  "Too many logs sent from here. Try again in an hour.":
      "Demasiados registros enviados desde aquí. Inténtalo de nuevo en una hora.",
  "Couldn't send the log. Check the internet connection and try again.":
      "No se pudo enviar el registro. Comprueba la conexión a Internet e inténtalo de nuevo.",
  // Recordings (Sports Trak recording, Recordings tab)
  "Watch live": "Ver en directo",
  "Play from the start": "Reproducir desde el principio",
  "What has been recorded so far": "Lo grabado hasta ahora",
  "Stop recording": "Detener la grabación",
  "Keeps what has been recorded": "Conserva lo grabado",
  "Cancel recording": "Cancelar la grabación",
  "Delete recording": "Eliminar la grabación",
  "Frees {size}": "Libera {size}",
  "Removes it from the list": "La quita de la lista",
  "Recordings": "Grabaciones",
  "Recording every {team} game": "Grabando cada partido de {team}",
  "Nothing recorded yet. Hold OK on a game in {tab} and pick Record, or hold OK on a live channel.":
      "Aún no hay grabaciones. Mantén OK en un partido de {tab} y elige Grabar, o mantén OK en un canal en directo.",
  "Recording now": "Grabando ahora",
  "Recorded": "Grabados",
  "{used} of {cap} GB used": "{used} usados de {cap} GB",
  "REC · {size}": "GRAB · {size}",
  "Waiting for a channel": "Esperando un canal",
  "Interrupted · {size}": "Interrumpida · {size}",
  "Missed": "Perdida",
  "Failed": "Fallida",
  "Live channel": "Canal en directo",
  "Start early: {min} min": "Empezar antes: {min} min",
  "Before the game's scheduled start": "Antes del inicio previsto del partido",
  "Keep recording: {min} min": "Seguir grabando: {min} min",
  "After the scheduled end, for overtime and delays":
      "Tras el final previsto, por prórrogas y retrasos",
  "Space for recordings: {gb} GB": "Espacio para grabaciones: {gb} GB",
  "{used} used. Recording stops when this is full or the storage has less than 1 GB left.":
      "{used} usados. La grabación se detiene cuando se llena o quedan menos de 1 GB libres.",
  "Save recordings to": "Guardar grabaciones en",
  "USB drive / SD card": "Unidad USB / tarjeta SD",
  "This device": "Este dispositivo",
  "{free} free of {total}": "{free} libres de {total}",
  "Plug in a USB drive or SD card to record to it. Recordings on this device are deleted if VesperTV is uninstalled.":
      "Conecta una unidad USB o una tarjeta SD para grabar en ella. Las grabaciones en este dispositivo se borran si se desinstala VesperTV.",
  "Recording in progress": "Grabación en curso",
  "{title} is recording on {channel}. Your playlist allows one connection, so playing another of its channels stops the recording.":
      "{title} se está grabando en {channel}. Tu lista permite una conexión, así que ver otro de sus canales detiene la grabación.",
  "Recording cancelled": "Grabación cancelada",
  "Not enough free space to record": "No hay espacio suficiente para grabar",
  "Recording {title}": "Grabando {title}",
  "{title} will be recorded": "{title} se grabará",
  "No longer recording every {team} game":
      "Ya no se graban los partidos de {team}",
  "Every {team} game will be recorded": "Se grabará cada partido de {team}",
  "Waiting for a channel in the guide": "Esperando un canal en la guía",
  "Record": "Grabar",
  "{channel} · starts now": "{channel} · empieza ahora",
  "{channel} · from {time}": "{channel} · desde las {time}",
  "Stop recording every {team} game": "Dejar de grabar cada partido de {team}",
  "Record every {team} game": "Grabar cada partido de {team}",
  "Recordings already made are kept": "Las grabaciones hechas se conservan",
  "One team at a time, on the channel {tab} picks":
      "Un equipo a la vez, en el canal que elige {tab}",
  "Replaces {team}": "Sustituye a {team}",
  "Recording stopped": "Grabación detenida",
  "Margins, space and where recordings are saved":
      "Márgenes, espacio y dónde se guardan",
  "Record until the show ends": "Grabar hasta que termine el programa",
  "Record until I stop it": "Grabar hasta que lo detenga",
  "Keeps going across shows (4 hours at most)":
      "Sigue entre programas (4 horas como máximo)",
  "{title} · stops at {time}": "{title} · se detiene a las {time}",
  "No guide for this channel: stops after 2 hours":
      "Sin guía para este canal: se detiene tras 2 horas",
  // Media Hub: Ready tag / Debrid accounts
  "Cleared": "Borrado",
  "Saved — key verified ✓": "Guardado — clave verificada ✓",
  "Saved, but {service} rejected the key — double-check it":
      "Guardado, pero {service} rechazó la clave — revísala",
  "Debrid accounts": "Cuentas debrid",
  "Optional keys for the \"Ready\" tag":
      "Claves opcionales para la etiqueta «Listo»",
  "Some Media Hub sources answer Play with a short \"being downloaded\" video while they fetch a title into your debrid account. VesperTV then checks back every minute and puts a \"Ready\" tag on the title's poster once it's there.":
      "Algunas fuentes del Media Hub responden a Reproducir con un video corto de «descargando» mientras traen un título a tu cuenta debrid. VesperTV vuelve a comprobar cada minuto y pone una etiqueta «Listo» en el póster del título cuando ya está.",
  "Optional: with your own key, your account confirms it directly. Without one, VesperTV asks the source again until the full file answers.":
      "Opcional: con tu propia clave, tu cuenta lo confirma directamente. Sin ella, VesperTV vuelve a preguntar a la fuente hasta que responda el archivo completo.",
  "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (API key). Kept in VesperTV and only used to read your downloads list.":
      "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (clave API). Se guarda en VesperTV y solo se usa para leer tu lista de descargas.",
  "Real-Debrid API token": "Token API de Real-Debrid",
  "TorBox API key": "Clave API de TorBox",
  // Sports Trak: League bank heading for college conferences
  "College": "Universitario",
  // Settings > General > Support VesperTV
  "Support VesperTV": "Apoyar VesperTV",
  "Buy a coffee or become a Supporter": "Invita un café o hazte Supporter",
  "VesperTV is free and always will be: no ads, no tracking, no paid features. If you enjoy it, you can buy a coffee or become a Supporter to help pay for the server, the website and development.":
      "VesperTV es gratis y siempre lo será: sin anuncios, sin rastreo, sin funciones de pago. Si te gusta, puedes invitar un café o hacerte Supporter para ayudar a pagar el servidor, el sitio web y el desarrollo.",
  "Supporting is a thank-you, never a paywall: everyone gets the same app.":
      "Apoyar es un agradecimiento, nunca un muro de pago: todos tienen la misma aplicación.",
  // Settings > General > Remote tips
  "Language and clock, what plays when the app starts, Fast startup, clearing your history, and remote tips.":
      "Idioma y reloj, qué se reproduce al iniciar, Inicio rápido, borrar el historial y trucos del control remoto.",
  "Remote tips": "Trucos del control",
  "Every hold menu and shortcut, on your phone":
      "Cada menú de mantener pulsado y atajo, en tu teléfono",
  "Every hold menu and remote shortcut, on one page: hold OK on channels, groups and posters, the side panel on ← in full screen, Multiview, Sports Trak and more.":
      "Cada menú de mantener pulsado y atajo del control en una sola página: mantener OK en canales, grupos y pósteres, el panel lateral con ← en pantalla completa, Multiview, Sports Trak y más.",
  "Scan with your phone, or open": "Escanea con tu teléfono, o abre",
  "Open": "Abrir",
  "The basics: hold OK (about half a second) opens a menu almost everywhere. Back always steps out one level. OK twice on a channel = full screen.":
      "Lo básico: mantener OK (medio segundo) abre un menú casi en todas partes. Atrás siempre sale un nivel. OK dos veces en un canal = pantalla completa.",
  "Fetching…": "Obteniendo…",
  // Media Hub: list-only sources
  "Plays through your other sources": "Se reproduce con tus otras fuentes",
  // Search: Media Hub results
  "Search Live TV, Movies, TV Shows & the Media Hub":
      "Buscar TV en vivo, películas, series y el Media Hub",
  // Player: what an unreadable link really served
  "This file's format can't be played here. Try another stream (an MKV or MP4 one).":
      "El formato de este archivo no se puede reproducir aquí. Prueba otra transmisión (MKV o MP4).",
  "Your source sent a message instead of the video:":
      "Tu fuente envió un mensaje en lugar del video:",
  "Check your source or debrid account (plan limits, active downloads), or pick another stream.":
      "Revisa tu fuente o tu cuenta debrid (límites del plan, descargas activas) o elige otra transmisión.",
  // Media Hub: import add-ons (pasted links, Stremio)
  "Added to the Media Hub: {names}": "Añadido al Media Hub: {names}",
  "Added to subtitle add-ons: {names}":
      "Añadido a los add-ons de subtítulos: {names}",
  "Already added: {names}": "Ya añadido: {names}",
  "Not usable in VesperTV: {names}": "No se puede usar en VesperTV: {names}",
  "Couldn't reach: {names}": "No se pudo acceder: {names}",
  "Import from Stremio": "Importar desde Stremio",
  "Couldn't reach Stremio. Check your internet connection.":
      "No se pudo conectar con Stremio. Revisa tu conexión a Internet.",
  "Couldn't read your Stremio add-ons. Try again.":
      "No se pudieron leer tus add-ons de Stremio. Inténtalo de nuevo.",
  "Copy the add-ons from your Stremio account. Nothing is changed on your Stremio account.":
      "Copia los add-ons de tu cuenta de Stremio. No se cambia nada en tu cuenta de Stremio.",
  "On your phone, scan the code or open":
      "En tu teléfono, escanea el código o abre",
  "Code": "Código",
  "Then sign in to Stremio there. This page continues on its own.":
      "Luego inicia sesión en Stremio allí. Esta página continúa sola.",
  "Your Stremio account has no add-ons VesperTV can copy.":
      "Tu cuenta de Stremio no tiene add-ons que VesperTV pueda copiar.",
  "Your Stremio add-ons. Untick any you don't want.":
      "Tus add-ons de Stremio. Desmarca los que no quieras.",
  "Add {n} add-ons": "Añadir {n} add-ons",
  "Already added": "Ya añadido",
  "Can't play in VesperTV": "No se puede reproducir en VesperTV",
  "Several links at once work too.":
      "También funcionan varios enlaces a la vez.",
  "{n} links checked": "{n} enlaces revisados",
  // Data pool on movies / episodes
  "Press OK while a channel, movie or episode plays to open a card with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Pulsa OK mientras se reproduce un canal, una película o un episodio para abrir una tarjeta con los detalles de la transmisión: resolución, fotogramas por segundo, códecs, bitrate, variantes de calidad, pistas de audio, búfer y HDR. Desactivado: OK muestra solo la info del canal.",
  "Stream details when you press OK while watching":
      "Detalles de la transmisión al pulsar OK mientras ves",
  // CFL official feed
  'East Division': 'División Este',
  'West Division': 'División Oeste',
  'Score unavailable': 'Marcador no disponible',
  'Passing yards': 'Yardas de pase',
  'Rushing yards': 'Yardas de carrera',
  'Net offence': 'Ataque neto',
  'First downs': 'Primeros downs',
  'Sacks': 'Capturas',
  '2nd down conversions': 'Conversiones de 2.º down',
  'Turnovers': 'Pérdidas de balón',
  'Penalties (yards)': 'Penalizaciones (yardas)',
  'Field goals': 'Goles de campo',
  'Time of possession': 'Tiempo de posesión',
  'Punting': 'Despejes',
  'Kickoffs': 'Saques iniciales',
  'Kickoff returns': 'Retornos de saque inicial',
  'Punt returns': 'Retornos de despeje',

  "Pick channels myself": "Elegir mis canales",
  "All groups": "Todos los grupos",
  "{count} selected": "{count} seleccionados",
  "Select results": "Seleccionar resultados",
  "Clear results": "Desmarcar resultados",
  "Browse all channels": "Ver todos los canales",
  "My sports channels": "Mis canales deportivos",
  "List name": "Nombre de la lista",
  "Add to list": "Añadir a la lista",
  "Create list": "Crear lista",
  "Edit list": "Editar lista",
  "Versions": "Versiones",
  "My lists": "Mis listas",
  "League networks": "Canales de ligas",
  "Sports networks": "Canales deportivos",
  "Regional channels": "Canales regionales",
  "Channels": "Canales",
  "Games": "Partidos",
  "Use a playlist group": "Usar un grupo de lista",
  "Rename list": "Renombrar lista",
  "Delete list": "Eliminar lista",

  "Filters": "Filtros",
  "Edit tags": "Editar etiquetas",
  "Country": "País",
  "Network": "Cadena",
  "Sport": "Deporte",
  "League": "Liga",
  "Group": "Grupo",
  "Unknown": "Desconocido",
  "Clear all": "Borrar todo",
  "Keep this list updated": "Mantener esta lista actualizada",
  "Comma-separated tags": "Etiquetas separadas por comas",
  "Add sources": "Añadir fuentes",
  "More sources": "Más fuentes",
  "Your added source": "Fuente añadida por ti",
  "This game": "Este partido",
  "hockey": "Hockey",
  "basketball": "Baloncesto",
  "football": "Fútbol americano",
  "soccer": "Fútbol",
  "baseball": "Béisbol",
  "tennis": "Tenis",
  "golf": "Golf",
  "racing": "Automovilismo",

  "Trailer": "Tráiler",
  "Cast": "Reparto",
  "Unable to open trailer": "No se pudo abrir el tráiler",
  "Next episode airs {date}": "El próximo episodio se emite el {date}",
  "Next episode: {code} · {date}": "Próximo episodio: {code} · {date}",
  "YouTube playback needs Android System WebView or Microsoft Edge WebView2.":
      "La reproducción de YouTube requiere Android System WebView o Microsoft Edge WebView2.",
  "YouTube could not play this video ({code}).":
      "YouTube no puede reproducir este vídeo ({code}).",
  "Open in YouTube": "Abrir en YouTube",
  "Back 10 seconds": "Retroceder 10 segundos",
  "Forward 10 seconds": "Avanzar 10 segundos",
  "Play / pause": "Reproducir / pausar",
  "Mark season watched": "Marcar temporada como vista",
  "Mark season unwatched": "Marcar temporada como no vista",
  "Season {season} marked as watched": "Temporada {season} marcada como vista",
  "Season {season} marked as unwatched":
      "Temporada {season} marcada como no vista",
  "Colour": "Color",
  "Kids profile": "Perfil infantil",
  "Photo": "Foto",
  "Profile": "Perfil",
  "Actions": "Acciones",
  "Active": "Activo",
  "Kids & PIN": "Niños y PIN",
  "Scan with your phone to add a photo":
      "Escanea con tu teléfono para añadir una foto",
  "Choose a photo": "Elegir una foto",
  "Remove photo": "Eliminar foto",
  "Choose a photo and tap Send to TV.": "Elige una foto y pulsa Enviar a TV.",
  "Your photo appears here automatically.":
      "Tu foto aparece aquí automáticamente.",
  "Could not read photo. Choose a JPEG or PNG under 2 MB.":
      "No se pudo leer la foto. Elige un JPEG o PNG de menos de 2 MB.",
  "Could not save profile. Try again.":
      "No se pudo guardar el perfil. Inténtalo de nuevo.",
  "Watch history": "Historial de reproducción",
  "Hidden groups and channels": "Grupos y canales ocultos",
  "Home rows layout": "Diseño de filas de inicio",
  "What should this profile get from Main?":
      "¿Qué debe copiar este perfil de Principal?",
  "Copies are independent. Playlists, accounts and device settings stay shared.":
      "Las copias son independientes. Listas, cuentas y ajustes del dispositivo siguen compartidos.",
  "Everything": "Todo",
  "None": "Nada",
  "Save name": "Guardar nombre",
  "Saving…": "Guardando…",
  "Profile restrictions are fixed when the profile is created.":
      "Las restricciones se fijan al crear el perfil.",
  "{n} groups allowed": "{n} grupos permitidos",
  "{groups} groups hidden · {channels} channels hidden":
      "{groups} grupos ocultos · {channels} canales ocultos",
  "Main cannot be deleted": "No se puede eliminar Principal",
  "Hold OK on a profile to edit it. Hold OK on a season to mark it watched or unwatched.":
      "Mantén OK en un perfil para editarlo o en una temporada para marcarla vista o no vista.",
  'Coming soon': 'Próximamente',
  "Show Cinemeta catalog": "Mostrar el catálogo de Cinemeta",
  "Show the default Popular, New and Featured rows and Cinemeta search results. Turn off to browse only your own catalogs. Posters and episode details may still use Cinemeta.":
      "Mostrar las filas predeterminadas Populares, Novedades y Destacados y los resultados de búsqueda de Cinemeta. Desactívalo para explorar solo tus propios catálogos. Los pósteres y los detalles de episodios pueden seguir usando Cinemeta.",
  "Expand": "Expandir",
  "Fill the screen with the Timeline guide":
      "Llenar la pantalla con la guía de programación",
  "The live channel fills the screen behind a see-through guide":
      "El canal en directo ocupa toda la pantalla detrás de una guía semitransparente",
  "Source: {source}": "Fuente: {source}",
  "File size: {size}": "Tamaño del archivo: {size}",
  "File size unavailable": "Tamaño del archivo no disponible",

  // Automatic detail trailers.
  "Automatic trailers": "Tráilers automáticos",
  "Play available trailers automatically with sound on IPTV and Media Hub movie and show pages.":
      "Reproducir automáticamente con sonido los tráilers disponibles en las páginas de películas y series de IPTV y Media Hub.",
  "Trailers": "Tráilers",
  "Play trailers automatically on movie and show pages":
      "Reproducción automática de tráilers en las páginas de películas y series",
  "On Fire TV sticks, the trailer plays full screen.":
      "En los Fire TV Stick, el tráiler se reproduce a pantalla completa.",
  "Remove \"{title}\" from history?": "¿Quitar «{title}» del historial?",
  "Import from storage": "Importar desde almacenamiento",
  "Add M3U playlists and Media Hub sources from USB or external storage":
      "Añadir listas M3U y fuentes de Media Hub desde USB o almacenamiento externo",
  "Choose a folder": "Elegir una carpeta",
  "Import from storage?": "¿Importar desde almacenamiento?",
  "Import": "Importar",
  "Import \"{name}\"? M3U playlists and included Media Hub sources are added without replacing your current setup.":
      "¿Importar «{name}»? Las listas M3U y las fuentes de Media Hub incluidas se añaden sin reemplazar tu configuración actual.",
  "Import M3U playlists and Media Hub source links from USB, SD card or external storage. Choose M3U/M3U8 playlists or TXT/JSON source files.":
      "Importa listas M3U y enlaces de fuentes de Media Hub desde USB, tarjeta SD o almacenamiento externo. Elige listas M3U/M3U8 o archivos de fuentes TXT/JSON.",
  "Could not read this storage location. Use Choose a folder to grant access.":
      "No se pudo leer esta ubicación. Usa Elegir una carpeta para conceder acceso.",
  "No folder picker on this device. Browse the storage devices below instead.":
      "Este dispositivo no tiene selector de carpetas. Explora los dispositivos de almacenamiento de abajo.",
  "No playlists or source files in this folder.":
      "No hay listas ni archivos de fuentes en esta carpeta.",
  "Imported {items} playlist items and {sources} Media Hub sources. {existing} sources already existed; {failed} could not be reached.":
      "Se importaron {items} elementos de listas y {sources} fuentes de Media Hub. {existing} fuentes ya existían; no se pudo contactar con {failed}.",
  "Could not import this file. Choose an M3U channel playlist or a TXT/JSON file containing Media Hub manifest links.":
      "No se pudo importar este archivo. Elige una lista de canales M3U o un archivo TXT/JSON con enlaces de manifiestos de Media Hub.",
  "Hide profiles": "Ocultar perfiles",
  "Hides the profiles row on Home.": "Oculta la fila de perfiles en Inicio.",
  "Preferred audio language": "Idioma de audio preferido",
  "Preferred subtitle language": "Idioma de subtítulos preferido",
  "Source default": "Predeterminado de la fuente",
  "Movies and episodes use these languages when available. Your manual track choices take priority when resuming.":
      "Las películas y los episodios usan estos idiomas cuando están disponibles. Tus selecciones manuales de pistas tienen prioridad al reanudar.",
  "Playback": "Reproducción",
  "Frame rate & resolution": "Frecuencia de imagen y resolución",
  "Video, audio, subtitles, trailers and player behaviour.":
      "Vídeo, audio, subtítulos, tráileres y comportamiento del reproductor.",
  "Theme, tabs, favourites and how the app looks.":
      "Tema, pestañas, favoritos y apariencia de la aplicación.",
  "Audio languages, subtitles and surround sound":
      "Idiomas de audio, subtítulos y sonido envolvente",
  "Media Hub playback": "Reproducción de Media Hub",
  "Default stream selection for movies and episodes":
      "Selección de transmisión predeterminada para películas y episodios",
  "Boxing": "Boxeo",
  "Stream sources": "Fuentes de reproducción",
  "Up/Down: browse · OK: switch · Back: close":
      "Arriba/Abajo: explorar · OK: cambiar · Atrás: cerrar",
  "Could not load stream sources.":
      "No se pudieron cargar las fuentes de reproducción.",
  "Could not switch stream. Try another source.":
      "No se pudo cambiar de fuente. Prueba otra.",
  "Current stream": "Fuente actual",
  "Size unknown": "Tamaño desconocido",
  "View source URL": "Ver URL de la fuente",
  "Source URL": "URL de la fuente",
  "Copy URL": "Copiar URL",
  "URL copied": "URL copiada",
  "Goals alert": "Alerta de goles",
  "Score alerts for My Teams on any screen":
      "Alertas de marcador de Mis equipos en cualquier pantalla",
  "Show a top-left popup when a team in My Teams scores. Alerts follow the score feed and pause when scores are hidden.":
      "Muestra un aviso arriba a la izquierda cuando marca un equipo de Mis equipos. Las alertas siguen las actualizaciones del marcador y se pausan si los marcadores están ocultos.",
  "{team} scored!": "¡{team} ha marcado!",
  "{first} {firstScore} – {secondScore} {second}":
      "{first} {firstScore} – {secondScore} {second}",
  'Catch-up is not available for this channel.':
      'La reproducción en diferido no está disponible para este canal.',
  'This programme is not available in catch-up.':
      'Este programa no está disponible en diferido.',
  "Hide Catch-up group": "Ocultar el grupo Diferido",
  "Removes the TV tab's Catch-up row (every channel you can replay).":
      "Quita la fila Diferido de la pestaña TV (todos los canales que se pueden volver a ver).",
  "No channels with catch-up.": "Ningún canal con diferido.",
  "Catch-up playlists": "Listas con diferido",
  "Hidden here · {n} channels": "Oculta aquí · {n} canales",
  'Catch-up': 'Diferido',
  'Previous programme': 'Programa anterior',
  'Next programme': 'Programa siguiente',
  'Watch from the start': 'Ver desde el principio',
  '{time} behind live': '{time} por detrás del directo',
  'Back to live': 'Volver al directo',
  'Catch-up {time}': 'Diferido {time}',
  'Now': 'Ahora',
  "Refined finish": "Acabado refinado",
  "Glossy surfaces, reflections and blur. Uses more graphics resources.":
      "Superficies brillantes, reflejos y desenfoque. Usa más recursos gráficos.",
  "Video HDR": "HDR del vídeo",
  "Decoder HDR": "HDR decodificado",
  "Unknown / not reported": "Desconocido / no indicado",
  "{format} (stream)": "{format} (flujo)",
  "{format} (decoder)": "{format} (decodificador)",
  "File size": "Tamaño del archivo",

  // Match-specific score alerts.
  "Remove goals alert for {league}": "Quitar alertas de goles de {league}",
  "Goals alert for all of {league}": "Alertas de goles de toda la {league}",
  "Notify me of every goal in this league (while VesperTV is open). Hide scores pauses alerts.":
      "Avisarme de cada gol de esta liga (con VesperTV abierto). Ocultar marcadores pausa las alertas.",
  "Watch game button": "Botón Ver partido",
  "A reminded game offers Watch game in the player at kickoff":
      "Un partido con recordatorio ofrece Ver partido en el reproductor al inicio",
  "When a reminded game is about to start, a Watch game button shows in the player for 10 minutes. Press Up from the player bar to reach it, then OK to switch to the game on its best channel. Set a reminder with a hold on the game. {app} must be open. Saved for this viewer.":
      "Cuando un partido con recordatorio está por empezar, un botón Ver partido aparece en el reproductor durante 10 minutos. Pulsa Arriba desde la barra del reproductor para llegar a él y OK para cambiar al partido en su mejor canal. Crea un recordatorio manteniendo OK en el partido. {app} debe estar abierto. Guardado para este perfil.",
  "Watch game": "Ver partido",
  "When the next episode starts by itself":
      "Cuándo empieza solo el siguiente episodio",
  "Play the next episode": "Reproducir el siguiente episodio",
  "30 seconds before the end": "30 segundos antes del final",
  "When the episode ends": "Al terminar el episodio",
  "Never": "Nunca",
  "{when}. On TV show episodes, the Up Next card counts down and the next episode starts by itself. Never: no countdown; the episode plays to its end.":
      "{when}. En episodios de series, la tarjeta A continuación cuenta hacia atrás y el siguiente episodio empieza solo. Nunca: sin cuenta atrás, el episodio se reproduce hasta el final.",
  "Set goals alert for this match":
      "Activar alertas de goles para este partido",
  "Remove goals alert for this match":
      "Quitar alertas de goles para este partido",
  "Notify me when either team scores (while VesperTV is open). Hide scores pauses alerts.":
      "Avisarme cuando marque cualquiera de los equipos (mientras VesperTV esté abierto). Ocultar los resultados pausa las alertas.",
  "Could not save score alert.": "No se pudo guardar la alerta de marcador.",
  // Game reminder timing.
  "1 hour before": "1 hora antes",
  "1 day before": "1 día antes",
  "1 week before": "1 semana antes",
  "At game time only": "Solo al comenzar el partido",
  "15 minutes before": "15 minutos antes",
  "Reminder timing": "Horario del recordatorio",
  "Advance reminders also notify at game time. VesperTV must be open.":
      "Los recordatorios anticipados también avisan al comenzar el partido. VesperTV debe estar abierto.",
  "This reminder time has passed": "La hora de este recordatorio ya pasó",
  "Choose when to be reminded (while VesperTV is open)":
      "Elige cuándo recibir el aviso (mientras VesperTV esté abierto)",
  "Starts in 1 hour": "Comienza en 1 hora",
  "Starts in 1 day": "Comienza en 1 día",
  "Starts in 1 week": "Comienza en 1 semana",
  "Schedule": "Calendario",
  "Every game of the season, cups included":
      "Todos los partidos de la temporada, copas incluidas",
  "Could not load the schedule.": "No se pudo cargar el calendario.",
  "OK: stats, watch or game menu · Hold OK: game menu · CH+/CH-: month":
      "OK: estadísticas, ver o menú del partido · Mantén OK: menú del partido · CH+/CH-: mes",
  "No game this day.": "No hay partido este día.",
  "Next game": "Próximo partido",
  "Newest": "Novedades",
  'What happens when a catch-up programme ends':
      "Qué pasa cuando termina un programa en diferido",
  'Keep playing after the programme': "Seguir reproduciendo tras el programa",
  "Off: catch-up pauses when the programme you picked ends, so the next one doesn't start on its own; press Play to carry on. On: it keeps going like the channel did.":
      "Desactivado: el diferido se pausa al terminar el programa elegido, así el siguiente no empieza solo; pulsa Reproducir para continuar. Activado: sigue como lo hizo el canal.",
  "Channel schedule": "Programación del canal",
  "▲ ▼ programmes  ·  OK to watch  ·  Back to close":
      "▲ ▼ programas  ·  OK para ver  ·  Atrás para cerrar",
  "On now  ·  OK to watch live": "En emisión  ·  OK para ver en directo",
  "Catch-up  ·  OK to watch from the start":
      "Catch-up  ·  OK para verlo desde el principio",
  "Upcoming": "Próximamente",
  "Show group counts": "Mostrar el número por grupo",
  "How many channels, movies or shows each group holds, beside its name.":
      "Cuántos canales, películas o series tiene cada grupo, junto a su nombre.",
  "{m} min back": "{m} min atrás",

  // Upcoming TV programmes
  "Starts in 5 minutes": "Empieza en 5 minutos",
  "5 minutes before and at programme time (while VesperTV is open)":
      "5 minutos antes y al comenzar el programa (con VesperTV abierto)",
  "Overlaps {title}. Your playlist has no free recording connection.":
      "Se solapa con {title}. Tu lista no tiene conexiones libres para grabar.",
  "Records the programme start to end. Manage it in Recordings.":
      "Graba el programa de principio a fin. Gestiona la grabación en Grabaciones.",
  "Could not schedule recording. Check recording storage and try again.":
      "No se pudo programar la grabación. Comprueba el almacenamiento e inténtalo de nuevo.",
  "▲ ▼ programmes  ·  OK for options  ·  Back to close":
      "▲ ▼ programas  ·  OK para opciones  ·  Atrás para cerrar",
  "Upcoming  ·  OK to remind or record":
      "Próximamente  ·  OK para recordar o grabar",
  "Recording scheduled. Android may delay the start without exact alarm access.":
      "Grabación programada. Android puede retrasar el inicio sin permiso para alarmas exactas.",

  // Plex media-server connector.
  "Connect Jellyfin / Emby / Plex": "Conectar Jellyfin / Emby / Plex",
  "Connect Plex": "Conectar Plex",
  "Sign in on your phone and choose a Plex server":
      "Inicia sesión en tu teléfono y elige un servidor Plex",
  "Sign in with Plex on your phone, then choose a server. Your movie and TV libraries appear in the Media Hub. Files play directly, without transcoding.":
      "Inicia sesión en Plex desde tu teléfono y elige un servidor. Tus bibliotecas de películas y series aparecen en el Media Hub. Los archivos se reproducen directamente, sin transcodificación.",
  "Could not connect to Plex. Try again.":
      "No se pudo conectar con Plex. Inténtalo de nuevo.",
  "Plex sign-in expired. Try again.":
      "El inicio de sesión de Plex ha caducado. Inténtalo de nuevo.",
  "Plex access was denied. Sign in again.":
      "Se denegó el acceso a Plex. Vuelve a iniciar sesión.",
  "Could not reach this Plex server. Check that it is online and accessible from this device.":
      "No se pudo acceder a este servidor Plex. Comprueba que esté conectado y sea accesible desde este dispositivo.",
  "Choose a Plex server": "Elige un servidor Plex",
  "No Plex servers are available on this account.":
      "No hay servidores Plex disponibles en esta cuenta.",
  "Sign in again": "Volver a iniciar sesión",
  "Scan the QR code or visit {url} and enter this code:":
      "Escanea el código QR o visita {url} e introduce este código:",

  // Title page row order.
  "Customize title page": "Personalizar la página del título",
  "Choose the order of rows below title details. Saved for this viewer.":
      "Elige el orden de las filas bajo los detalles del título. Se guarda para este perfil.",

  // My Teams preferred channel.
  "Set preferred channel": "Elegir canal preferido",
  "Automatic channel": "Canal automático",
  "Preferred channel for {team}": "Canal preferido para {team}",
  "Saved channel is unavailable": "El canal guardado no está disponible",
  "Hold OK on a team for schedule, preferred channel or unfollow · on a game to pick the channel":
      "Mantén OK en un equipo: calendario, canal preferido o dejar de seguir · en un partido: elegir canal",

  // Sports channel country preferences.
  "Channel preferences and settings for {tab}.":
      "Preferencias de canales y ajustes de {tab}.",
  "Preferred channel countries": "Países preferidos para los canales",
  "Prefer local channels while keeping other matches available":
      "Prioriza los canales locales manteniendo disponibles las demás coincidencias",
  "Prefer these countries among channels that match the game. Other countries remain available. Your game and team channel choices still come first.":
      "Prioriza estos países entre los canales que coinciden con el partido. Los demás países siguen disponibles. Tus canales elegidos para partidos y equipos siguen teniendo prioridad.",
  "Selected countries have equal priority. Match evidence comes before country, then video quality within each group. Saved for this viewer.":
      "Los países seleccionados tienen la misma prioridad. La evidencia del partido va antes del país y después se considera la calidad dentro de cada grupo. Se guarda para este perfil.",
  "No country preference": "Sin preferencia de país",
  "Keep the current automatic ranking": "Mantener el orden automático actual",
  "Canada": "Canadá",
  "United States": "Estados Unidos",
  "United Kingdom": "Reino Unido",
  "Portugal": "Portugal",
  "Greece": "Grecia",
  "Ireland": "Irlanda",
  "Netherlands": "Países Bajos",
  "Belgium": "Bélgica",
  "Switzerland": "Suiza",
  "Austria": "Austria",
  "Denmark": "Dinamarca",
  "Sweden": "Suecia",
  "Norway": "Noruega",
  "Finland": "Finlandia",
  "Poland": "Polonia",
  "Czechia": "Chequia",
  "Slovakia": "Eslovaquia",
  "Hungary": "Hungría",
  "Romania": "Rumanía",
  "Bulgaria": "Bulgaria",
  "Croatia": "Croacia",
  "Serbia": "Serbia",
  "Slovenia": "Eslovenia",
  "Bosnia and Herzegovina": "Bosnia y Herzegovina",
  "Albania": "Albania",
  "Türkiye": "Turquía",
  "Ukraine": "Ucrania",
  "Australia": "Australia",
  "New Zealand": "Nueva Zelanda",
  "Brazil": "Brasil",
  "Mexico": "México",
  "Argentina": "Argentina",
  "Cyprus": "Chipre",
  "Estonia": "Estonia",
  "Latvia": "Letonia",
  "Lithuania": "Lituania",
  "Luxembourg": "Luxemburgo",
  "Malta": "Malta",
  "Iceland": "Islandia",
  // Sports preferred playlist.
  "Preferred playlist": "Lista preferida",
  "Try matching channels from this playlist first":
      "Buscar primero canales coincidentes en esta lista",
  "Among comparable game matches, prefer this playlist, then your preferred countries, then video quality. Your game and team channel choices still come first. Other playlists remain available.":
      "Entre coincidencias comparables, prioriza esta lista, después tus países preferidos y luego la calidad del vídeo. Tus elecciones de canal para partidos y equipos siguen teniendo prioridad. Las demás listas siguen disponibles.",
  "Your preferred playlist is unavailable or disabled. Other matching playlists will be used.":
      "Tu lista preferida no está disponible o está desactivada. Se usarán otras listas con coincidencias.",
  "No playlist preference": "Sin preferencia de lista",
  "Disabled": "Desactivada",
  "No playlists yet": "Aún no hay listas",
  "Selected countries have equal priority. Match evidence comes first, then preferred playlist, country and video quality. Saved for this viewer.":
      "Los países seleccionados tienen la misma prioridad. Primero se valora la coincidencia del partido, después la lista preferida, el país y la calidad del vídeo. Se guarda para este perfil.",
  "Rank countries equally": "Dar la misma prioridad a todos los países",
  // Hide empty sports leagues.
  "Hide leagues with no games": "Ocultar ligas sin partidos",
  "Show only leagues with games on the selected day":
      "Mostrar solo las ligas con partidos el día seleccionado",
  "Follows the selected day in Sports Trak. Leagues stay visible while schedules are loading or unavailable. Your saved leagues and their order are kept in Edit leagues. Saved for this viewer.":
      "Sigue el día seleccionado en Sports Trak. Las ligas permanecen visibles mientras se cargan los calendarios o si no están disponibles. Tus ligas y su orden se conservan en Editar ligas. Se guarda para este perfil.",
  // Updater storage and download checks.
  "Free about {mb} MB and try again.":
      "Libera unos {mb} MB y vuelve a intentarlo.",
  "Could not check free storage. Restart VesperTV and try again.":
      "No se pudo comprobar el espacio libre. Reinicia VesperTV y vuelve a intentarlo.",
  "Could not check the update size. Check for updates and try again.":
      "No se pudo comprobar el tamaño de la actualización. Busca actualizaciones y vuelve a intentarlo.",
  "Download failed. Please try again.":
      "La descarga ha fallado. Vuelve a intentarlo.",
  // IPTV cast portraits.
  "Metadata provided by TMDB.": "Metadatos proporcionados por TMDB.",
  "No matching title found in your playlists.":
      "No se ha encontrado un título coincidente en tus listas.",
  "Skip intro": "Saltar intro",
  "Skip recap": "Saltar resumen",
  "Skip credits": "Saltar créditos",
  "Skip intro and credits button": "Botón para saltar la intro y los créditos",
  "Skip intros and credits on TV show episodes":
      "Saltar la intro y los créditos en los episodios",
  "On TV show episodes, a button skips the intro, the recap and the credits (or plays the next episode). Press OK while it shows. Times come from IntroDB (introdb.app), a free community database: it is asked with the show's IMDb id, season and episode number, nothing else.":
      "En los episodios de series, un botón salta la intro, el resumen y los créditos (o reproduce el siguiente episodio). Pulsa OK mientras aparece. Los tiempos vienen de IntroDB (introdb.app), una base comunitaria gratuita: solo se le envía el id de IMDb de la serie, la temporada y el número de episodio.",
  "Betting odds": "Cuotas de apuestas",
  "Show betting odds": "Mostrar las cuotas",
  "The line and over/under on game cards, more in the game stats":
      "La línea y el total (over/under) en las tarjetas de partido, más en las estadísticas",
  "Show the line and over/under on games":
      "Mostrar la línea y el total de los partidos",
  "Odds come with the scores (one sportsbook, mostly North American leagues) and show before and during a game. Display only: {app} never takes bets or links to a sportsbook. Saved for this viewer.":
      "Las cuotas llegan con los marcadores (una sola casa de apuestas, sobre todo ligas norteamericanas) y se muestran antes y durante un partido. Solo se muestran: {app} nunca acepta apuestas ni enlaza a una casa de apuestas. Guardado para este perfil.",
  "Moneyline": "Ganador",
  "Spread": "Hándicap",
  "Over": "Más",
  "Under": "Menos",
  "Draw": "Empate",
  "Favourite": "Favorito",
  "Total": "Total",
  "Betting odds · {book}": "Cuotas · {book}",
  "Playlist editor": "Editor de listas",
  "Rename, hide copies, fallbacks and stream test, from your phone or PC": "Renombrar, ocultar copias, canales de respaldo y prueba de streams, desde tu móvil o PC",
  "Rename, change logos, hide copies and dead streams, set fallback channels and clean up the guide, from your phone or PC. Your provider's playlist is never changed: edits are kept on this device and run again on every content update.": "Renombra canales, cambia logos, oculta copias y streams caídos, elige canales de respaldo y limpia la guía, desde tu móvil o PC. La lista de tu proveedor nunca se modifica: los cambios se guardan en este dispositivo y se aplican de nuevo en cada actualización.",
  "Could not open the editor: {e}": "No se pudo abrir el editor: {e}",
  "Phone: scan the code.": "Móvil: escanea el código.",
  "PC: open this address in a browser": "PC: abre esta dirección en un navegador",
  "and enter the code": "e introduce el código",
  "Same Wi-Fi or network as this device. The editor closes when you leave this screen.": "Misma Wi-Fi o red que este dispositivo. El editor se cierra al salir de esta pantalla.",
  "Open in browser": "Abrir en el navegador",
  "Saved from your phone or PC: {name}": "Guardado desde tu móvil o PC: {name}",
  "Stream test {done}/{total}: {name}": "Prueba de streams {done}/{total}: {name}",
  "Stream test: {done}/{total} tested.": "Prueba de streams: {done}/{total} probados.",
  "Switch to another copy when a channel fails": "Cambiar a otra copia cuando un canal falla",
  "If a channel doesn't start or keeps dropping, play its next copy (FHD, then HD…) or your fallback channels, without an error screen.": "Si un canal no arranca o se corta, se reproduce su siguiente copia (FHD, luego HD…) o tus canales de respaldo, sin pantalla de error.",
  "Hide lower-quality copies": "Ocultar copias de menor calidad",
  "Only the best copy of each channel is listed; the others stay as automatic fallbacks.": "Solo se muestra la mejor copia de cada canal; las demás quedan como respaldo automático.",
  "Hide separator rows": "Ocultar filas separadoras",
  "Rows like ##### SPORTS #####": "Filas como ##### SPORTS #####",
  "{n} channels hidden by the editor": "{n} canales ocultos por el editor",
  "Rename channel": "Renombrar canal",
  "Channel name": "Nombre del canal",
  "Rename…": "Renombrar…",
  "Use the provider's name": "Usar el nombre del proveedor",
  "Trying another copy: {name}": "Probando otra copia: {name}",
  "Previous month": "Mes anterior",
  "Next month": "Mes siguiente",
  "Pause": "Pausa",
  "No guide information": "Sin información de guía",
  "Playing {name}": "Reproduciendo {name}",
  "Up": "Arriba",
  "Down": "Abajo",
  "Recently added": "Añadidos recientemente",
  "Recently added channels": "Canales añadidos recientemente",
  "Adds a TV tab group with the channels your playlists added in the last 14 days.": "Añade un grupo en la pestaña TV con los canales que tus listas añadieron en los últimos 14 días.",
  "No channels added in the last 14 days.": "Ningún canal añadido en los últimos 14 días.",
  "Live buffer": "Búfer en directo",
  "Hide short dropouts on live channels": "Oculta los cortes breves en los canales en directo",
  "Small (1.5 seconds)": "Pequeño (1,5 segundos)",
  "4 seconds": "4 segundos",
  "8 seconds": "8 segundos",
  "12 seconds": "12 segundos",
  "{size}. Live channels store this much before playing, so short dropouts from the server don't show. Bigger hides longer dropouts, but channels start later and play that much behind live. Applies from the next channel.": "{size}. Los canales en directo guardan esta reserva antes de reproducir, para que los cortes breves del servidor no se vean. Más grande oculta cortes más largos, pero los canales tardan más en empezar y van ese tiempo por detrás del directo. Se aplica desde el siguiente canal.",
  "Seasons": "Temporadas",
  "Playlist editor (Test flight)": "Editor de listas (Test flight)",
};
