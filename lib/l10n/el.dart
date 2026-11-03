/// Greek UI strings, keyed by the English text in the code (see l10n.dart).
///
/// Standard Greek, polite plural (Πατήστε, Επιλέξτε). TV labels are often
/// narrow, so short forms are used on purpose (Ν/Η/Ι for standings, λεπ.).
/// Keep every `{placeholder}` exactly as in the key. `{s}` is an
/// English-style plural "s" filled in by the code; Greek plurals don't
/// work that way, so those strings are phrased without it.
const Map<String, String> kEl = {
  "Discord": "Discord",
  "Direct support through Discord": "Άμεση υποστήριξη μέσω Discord",
  "Questions, help with setup, feature ideas and release news: join the VesperTV community on Discord.":
      "Ερωτήσεις, βοήθεια με τη ρύθμιση, ιδέες και νέα εκδόσεων: μπες στην κοινότητα του VesperTV στο Discord.",
  "VesperTV is free, with no ads. See how you can help keep it running.":
      "Το VesperTV είναι δωρεάν, χωρίς διαφημίσεις. Δείτε πώς μπορείτε να βοηθήσετε.",
  "Show a test popup": "Δοκιμαστικό αναδυόμενο",
  "A sample goal alert for 8 seconds.":
      "Ένα δείγμα ειδοποίησης γκολ για 8 δευτερόλεπτα.",
  "Guide": "Οδηγός",
  "Live TV guide layout, full-screen video, compact rows":
      "Διάταξη οδηγού, βίντεο πλήρους οθόνης, συμπαγείς γραμμές",
  "{n} titles": "{n} τίτλοι",
  "Open groups as expanded catalog": "Άνοιγμα ομάδων ως εκτεταμένος κατάλογος",
  "Movies and TV Shows groups open the full poster grid instead of the rows.":
      "Οι ομάδες Ταινιών και Σειρών ανοίγουν το πλήρες πλέγμα αφισών αντί για σειρές.",
  "Compact guide": "Συμπαγής οδηγός",
  "Shorter Timeline rows so more channels fit in the same space.":
      "Πιο χαμηλές γραμμές στο χρονοδιάγραμμα για περισσότερα κανάλια.",
  "Transparent popups": "Διάφανα αναδυόμενα",
  "Reminders and goal alerts lose their background and outline, keeping only the logo and text.":
      "Οι υπενθυμίσεις και οι ειδοποιήσεις γκολ χάνουν φόντο και περίγραμμα, κρατώντας μόνο το λογότυπο και το κείμενο.",
  "Use with playlist": "Χρήση με τη λίστα",
  "Save EPG URL": "Αποθήκευση URL οδηγού",
  "Custom EPG URL saved.": "Το προσαρμοσμένο URL οδηγού αποθηκεύτηκε.",
  "Custom EPG URL cleared.": "Το προσαρμοσμένο URL οδηγού αφαιρέθηκε.",
  "Pick a playlist, then paste a third-party XMLTV link. Leave it blank to use the guide of that playlist. A channel is only filled in when the ids in the feed match the playlist.":
      "Διάλεξε μια λίστα και επικόλλησε έναν σύνδεσμο XMLTV τρίτου. Άφησέ το κενό για τον οδηγό της λίστας. Ένα κανάλι συμπληρώνεται μόνο αν τα ids της πηγής ταιριάζουν με της λίστας.",
  // Sports Trak quality preference (moved from the league bar).
  "Prefer higher-quality channels among game matches":
      "Προτίμηση καναλιών υψηλότερης ποιότητας που αντιστοιχούν στον αγώνα",
  "On by default. Your saved channel choices still come first. Turn this off to keep the usual match order. Saved for this viewer.":
      "Ενεργό από προεπιλογή. Οι αποθηκευμένες επιλογές καναλιών σας παραμένουν πρώτες. Απενεργοποιήστε το για να διατηρήσετε τη συνήθη σειρά αντιστοίχισης. Αποθηκεύεται για αυτό το προφίλ.",
  // Android phone player touch lock.
  "Lock touch controls": "Κλείδωμα χειριστηρίων αφής",
  "Unlock touch controls": "Ξεκλείδωμα χειριστηρίων αφής",
  "Touch controls locked": "Τα χειριστήρια αφής είναι κλειδωμένα",
  // Media Hub custom posters.
  "Add {imdb_id} or {tmdb_id} where the title goes.":
      "Προσθέστε {imdb_id} ή {tmdb_id} στη θέση του τίτλου.",
  "Custom posters": "Προσαρμοσμένες αφίσες",
  "Custom posters off: Media Hub shows the sources' posters.":
      "Οι προσαρμοσμένες αφίσες απενεργοποιήθηκαν: το Media Hub δείχνει τις αφίσες των πηγών.",
  "Example: {url}": "Παράδειγμα: {url}",
  "Media Hub posters from a poster service":
      "Αφίσες Media Hub από υπηρεσία αφισών",
  "Poster address": "Διεύθυνση αφισών",
  "Saved. Media Hub posters now come from this address.":
      "Αποθηκεύτηκε. Οι αφίσες του Media Hub προέρχονται πλέον από αυτή τη διεύθυνση.",
  "Show Media Hub posters from a poster service of your choice, for example one that adds ratings. Paste its poster address with {imdb_id} (or {tmdb_id}) where the title goes; include your own key if the service needs one.":
      "Εμφανίστε τις αφίσες του Media Hub από υπηρεσία της επιλογής σας, π.χ. μία που προσθέτει βαθμολογίες. Επικολλήστε τη διεύθυνση αφίσας με {imdb_id} (ή {tmdb_id}) στη θέση του τίτλου· προσθέστε το δικό σας κλειδί αν το ζητά η υπηρεσία.",
  "Turn off": "Απενεργοποίηση",
  "When a title has no matching ID, its normal poster is shown. Leave empty to turn it off.":
      "Αν ένας τίτλος δεν έχει το αντίστοιχο αναγνωριστικό, εμφανίζεται η κανονική του αφίσα. Αφήστε κενό για απενεργοποίηση.",
  // Media Hub experience (progressive sources, rows, discovery).
  "Add your TMDB key for collections and cast credits":
      "Προσθέστε το κλειδί TMDB για συλλογές και ηθοποιούς",
  "Airs {date}": "Προβολή {date}",
  "All sources": "Όλες οι πηγές",
  "Any source": "Οποιαδήποτε πηγή",
  "Auto-play preferred stream": "Αυτόματη αναπαραγωγή προτιμώμενης ροής",
  "Cast and credits": "Ηθοποιοί και συντελεστές",
  "Collection": "Συλλογή",
  "Continue series": "Συνέχεια σειράς",
  "Could not load credits.": "Δεν ήταν δυνατή η φόρτωση των συντελεστών.",
  "Could not load this title. Try again.":
      "Δεν ήταν δυνατή η φόρτωση του τίτλου. Δοκιμάστε ξανά.",
  "Customize": "Προσαρμογή",
  "Customize Media Hub": "Προσαρμογή Media Hub",
  "Customize rows": "Προσαρμογή σειρών",
  "Explore more": "Εξερευνήστε περισσότερα",
  "Explore this genre": "Εξερευνήστε αυτό το είδος",
  "Hide a row without disabling its playback source.":
      "Απόκρυψη σειράς χωρίς απενεργοποίηση της πηγής αναπαραγωγής της.",
  "Hide row": "Απόκρυψη σειράς",
  "If no stream matches, choose one manually. Format and language information comes from your sources.":
      "Αν καμία ροή δεν ταιριάζει, επιλέξτε μία χειροκίνητα. Οι πληροφορίες μορφής και γλώσσας προέρχονται από τις πηγές σας.",
  "Leave empty to reset": "Αφήστε κενό για επαναφορά",
  "Loading": "Φόρτωση",
  "Loading recommendations…": "Φόρτωση προτάσεων…",
  "Looking for streams…": "Αναζήτηση ροών…",
  "Maximum quality": "Μέγιστη ποιότητα",
  "More like this": "Παρόμοια",
  "No compatible source for this title. Add a playback source in Media Hub settings.":
      "Καμία συμβατή πηγή για αυτόν τον τίτλο. Προσθέστε πηγή αναπαραγωγής στις ρυθμίσεις του Media Hub.",
  "No credits found.": "Δεν βρέθηκαν συντελεστές.",
  "No results": "Κανένα αποτέλεσμα",
  "No streams": "Καμία ροή",
  "Pin row": "Καρφίτσωμα σειράς",
  "Playback preferences": "Προτιμήσεις αναπαραγωγής",
  "Prefer SDR": "Προτίμηση SDR",
  "Preferred source": "Προτιμώμενη πηγή",
  "Rename row": "Μετονομασία σειράς",
  "Results": "Αποτελέσματα",
  "Retry recommendations": "Επανάληψη προτάσεων",
  "Search sources": "Πηγές αναζήτησης",
  "Show row": "Εμφάνιση σειράς",
  "Sources": "Πηγές",
  "Sources · searching…": "Πηγές · αναζήτηση…",
  "Unavailable": "Μη διαθέσιμο",
  "subtitles": "υπότιτλοι",
  // Sports matchup information and activation.
  "Key stats": "Βασικά στατιστικά",
  "Latest goal": "Τελευταίο γκολ",
  "Last play": "Τελευταία φάση",
  "Game situation": "Εξέλιξη αγώνα",
  "OK: watch here  ·  Hold: pick the channel":
      "OK: προβολή εδώ  ·  Παρατεταμένα: επιλογή καναλιού",
  "Click: watch here  ·  Hold: pick the channel":
      "Κλικ: προβολή εδώ  ·  Παρατεταμένα: επιλογή καναλιού",
  "Open full Live TV": "Άνοιγμα πλήρους Live TV",
  // Startup profile selector.
  "Launch with profiles selector": "Εκκίνηση με επιλογή προφίλ",
  "Choose a profile after the splash, before the app opens. Applies from the next start.":
      "Επιλέξτε προφίλ μετά την οθόνη εκκίνησης, πριν ανοίξει η εφαρμογή. Ισχύει από την επόμενη εκκίνηση.",
  "Who is watching?": "Ποιος παρακολουθεί;",
  "Choose your profile to get started.":
      "Επιλέξτε το προφίλ σας για να ξεκινήσετε.",
  "Welcome, {name}": "Καλώς ήρθες, {name}",
  "Could not switch profile. Please try again.":
      "Δεν ήταν δυνατή η αλλαγή προφίλ. Δοκιμάστε ξανά.",

  "Sports Mode": "Λειτουργία αθλητικών",
  "Make Sports Trak your home, with your top five leagues at the side.":
      "Ορίστε το Sports Trak ως αρχική οθόνη, με τις πέντε πρώτες λίγκες σας στο πλάι.",
  "Could not change Sports Mode. Try again.":
      "Δεν ήταν δυνατή η αλλαγή της λειτουργίας αθλητικών. Δοκιμάστε ξανά.",
  // Media Hub source cards.
  "Enabled": "Ενεργή",
  "Catalogs from Cinemeta": "Κατάλογοι από το Cinemeta",
  "Media server": "Διακομιστής πολυμέσων",
  "Tracker lists": "Λίστες παρακολούθησης",
  "Catalogs only": "Μόνο κατάλογοι",
  "Streams only": "Μόνο ροές",
  "Catalogs + streams": "Κατάλογοι + ροές",
  "Provides video playback": "Παρέχει αναπαραγωγή βίντεο",
  "Refresh Media Hub after changing Other.":
      "Ανανεώστε το Media Hub αφού αλλάξετε το Άλλα.",
  "Playback sources": "Πηγές αναπαραγωγής",
  "These sources provide the video when you press Play.":
      "Αυτές οι πηγές παρέχουν το βίντεο όταν πατάτε Αναπαραγωγή.",
  "No playback sources yet.": "Δεν υπάρχουν ακόμη πηγές αναπαραγωγής.",
  "Catalogs & lists": "Κατάλογοι και λίστες",
  "Discover titles here; playback comes from your sources above.":
      "Ανακαλύψτε τίτλους εδώ· η αναπαραγωγή γίνεται από τις παραπάνω πηγές σας.",
  "Popular · New · Featured": "Δημοφιλή · Νέα · Προτεινόμενα",
  "Catalogs for stream-only sources":
      "Κατάλογοι για πηγές που προσφέρουν μόνο ροές",
  "Posters and episode details may still use Cinemeta when this is off.":
      "Οι αφίσες και οι λεπτομέρειες επεισοδίων μπορεί να χρησιμοποιούν το Cinemeta ακόμη κι όταν αυτό είναι ανενεργό.",
  "Hold OK on Enabled to remove a source.":
      "Κρατήστε πατημένο το OK στο Ενεργή για να αφαιρέσετε μια πηγή.",
  "Show under Other keeps a source behind the Other genre filter in Movies and TV Shows.":
      "Η Εμφάνιση στα Άλλα τοποθετεί μια πηγή στο φίλτρο είδους Άλλα στις Ταινίες και Σειρές.",

  "Remove from history": "Αφαίρεση από το ιστορικό",
  "Automatically play the largest file":
      "Αυτόματη αναπαραγωγή του μεγαλύτερου αρχείου",
  "Use the largest known file size when starting a title. Resume keeps your selected stream.":
      "Επιλέγει το μεγαλύτερο γνωστό αρχείο στην έναρξη. Η συνέχιση διατηρεί την επιλεγμένη ροή.",
  "Prefer highest quality": "Προτίμηση υψηλότερης ποιότητας",
  "Remind me for every game: {team}": "Υπενθύμιση για κάθε αγώνα: {team}",
  "Stop team reminders: {team}": "Διακοπή υπενθυμίσεων: {team}",
  "Remind me": "Υπενθύμιση αγώνα",
  "Cancel reminder": "Ακύρωση υπενθύμισης",
  "15 minutes before and at game time (while VesperTV is open)":
      "15 λεπτά πριν και στην έναρξη (με το VesperTV ανοιχτό)",
  "Reminder set": "Η υπενθύμιση ορίστηκε",
  "Reminder cancelled": "Η υπενθύμιση ακυρώθηκε",
  "Could not save reminder.": "Δεν ήταν δυνατή η αποθήκευση της υπενθύμισης.",
  "This game has already started.": "Αυτός ο αγώνας έχει ήδη ξεκινήσει.",
  "Your team: {home} vs {away}": "Η ομάδα σας: {home} εναντίον {away}",
  "Starts in 15 minutes": "Ξεκινά σε 15 λεπτά",
  "Is about to start": "Πρόκειται να ξεκινήσει",

  "Display": "Οθόνη",
  "Match the TV to the video's frame rate and resolution":
      "Προσαρμογή της τηλεόρασης στον ρυθμό καρέ και την ανάλυση του βίντεο",
  "Match frame rate": "Προσαρμογή ρυθμού καρέ",
  "Switches the TV to the video's frame rate a few seconds after it starts (50 Hz for UK and European channels, 24 Hz for films), for smooth motion. The screen goes black for a second or two while the TV switches; channels with the same rate don't switch again. Leaving the app gives the TV its own setting back.":
      "Αλλάζει την τηλεόραση στον ρυθμό καρέ του βίντεο λίγα δευτερόλεπτα μετά την έναρξη (50 Hz για βρετανικά και ευρωπαϊκά κανάλια, 24 Hz για ταινίες), για ομαλή κίνηση. Η οθόνη μαυρίζει για ένα-δυο δευτερόλεπτα κατά την αλλαγή· κανάλια με τον ίδιο ρυθμό δεν αλλάζουν ξανά. Όταν βγαίνετε από την εφαρμογή, η τηλεόραση επιστρέφει στη δική της ρύθμιση.",
  "Only switch between 50 and 60 Hz": "Αλλαγή μόνο μεταξύ 50 και 60 Hz",
  "Films at 24 frames per second keep the current rate, so fewer switches.":
      "Οι ταινίες στα 24 καρέ ανά δευτερόλεπτο κρατούν τον τρέχοντα ρυθμό, άρα λιγότερες αλλαγές.",
  "Match resolution": "Προσαρμογή ανάλυσης",
  "Switches the TV to the video's resolution (1080p, 4K…) so the TV does the upscaling. Off: this device scales every video to its current resolution.":
      "Αλλάζει την τηλεόραση στην ανάλυση του βίντεο (1080p, 4K…) ώστε την κλιμάκωση να την κάνει η τηλεόραση. Ανενεργό: αυτή η συσκευή κλιμακώνει κάθε βίντεο στην τρέχουσα ανάλυσή της.",
  "Stream HDR": "HDR ροής",
  "No (SDR)": "Όχι (SDR)",
  "Home": "Αρχική",
  "Today's games": "Σημερινοί αγώνες",
  "Recent channels": "Πρόσφατα κανάλια",
  "Favourite channels": "Αγαπημένα κανάλια",
  "New movies": "Νέες ταινίες",
  "New TV shows": "Νέες σειρές",
  'Series': "Σειρά",
  "Movie": "Ταινία",
  "Move row up": "Μετακίνηση σειράς πάνω",
  "Move row down": "Μετακίνηση σειράς κάτω",
  "Hide this row": "Απόκρυψη σειράς",
  "Edit Home rows…": "Επεξεργασία σειρών Αρχικής…",
  "Home rows": "Σειρές Αρχικής",
  "Nothing here yet. Watch a channel, a movie or a show and it shows up on Home.":
      "Τίποτα ακόμα. Δείτε ένα κανάλι, μια ταινία ή μια σειρά και θα εμφανιστεί στην Αρχική.",
  "Native video surface (beta)": "Εγγενής επιφάνεια βίντεο (beta)",
  "Plays the picture the way native TV apps do, for HDR that looks washed out or green flashes under the guide (Fire TV Cube, NVIDIA Shield). Restart the app after changing it. If the picture is missing, in the wrong place or menus look wrong, turn it off and send us a log.":
      "Εμφανίζει την εικόνα όπως οι εγγενείς εφαρμογές TV, για HDR που φαίνεται ξεθωριασμένο ή πράσινες αναλαμπές κάτω από τον οδηγό (Fire TV Cube, NVIDIA Shield). Επανεκκινήστε την εφαρμογή μετά την αλλαγή. Αν η εικόνα λείπει, είναι σε λάθος θέση ή τα μενού φαίνονται λάθος, απενεργοποιήστε το και στείλτε μας ένα αρχείο καταγραφής.",
  "Close the app completely and open it again to apply this change.":
      "Κλείστε εντελώς την εφαρμογή και ανοίξτε την ξανά για να εφαρμοστεί η αλλαγή.",
  "Green flicker fix (test)": "Διόρθωση πράσινου τρεμοπαίγματος (δοκιμή)",
  "For green flashes on the picture while the guide or a menu is over it (NVIDIA Shield). Unlike Compatibility video it keeps HDR. Applies from the next channel. If the guide or menus disappear behind the video, turn it off.":
      "Για πράσινες αναλαμπές στην εικόνα όταν ο οδηγός ή ένα μενού είναι από πάνω (NVIDIA Shield). Σε αντίθεση με το Συμβατό βίντεο, διατηρεί το HDR. Ισχύει από το επόμενο κανάλι. Αν ο οδηγός ή τα μενού χαθούν πίσω από το βίντεο, απενεργοποιήστε το.",
  'Automatic: on for this device.': 'Αυτόματο: ενεργό για αυτή τη συσκευή.',
  '1 hour': '1 ώρα',
  '{h} hours': '{h} ώρες',

  'Sort groups': 'Ταξινόμηση ομάδων',
  'Provider order': 'Σειρά παρόχου',
  'Name A–Z': 'Όνομα Α–Ω',
  'Name Z–A': 'Όνομα Ω–Α',

  "Starting...": "Εκκίνηση…",
  "Content updated": "Το περιεχόμενο ενημερώθηκε",
  "Startup failed:\n{bootstrapError}": "Η εκκίνηση απέτυχε:\n{bootstrapError}",
  "Retry": "Ξανά",
  "Your catalog has never been fully synced.":
      "Ο κατάλογος δεν έχει συγχρονιστεί ποτέ πλήρως.",
  "Your catalog was last fully synced earlier today.":
      "Ο κατάλογος συγχρονίστηκε πλήρως νωρίτερα σήμερα.",
  "Your catalog was last fully synced {days} day{s} ago.":
      "Τελευταίος πλήρης συγχρονισμός καταλόγου: πριν από {days} ημ.",
  "Update content now?": "Ενημέρωση περιεχομένου τώρα;",
  "This can take a few minutes on a large catalog. Skipping opens the app with what's already cached.":
      "Σε μεγάλο κατάλογο μπορεί να πάρει λίγα λεπτά. Αν το παραλείψετε, η εφαρμογή ανοίγει με ό,τι είναι ήδη αποθηκευμένο.",
  "Skip for now": "Όχι τώρα",
  "Update": "Ενημέρωση",
  "Loading movies & TV shows...": "Φόρτωση ταινιών και σειρών…",
  "Connecting to server...": "Σύνδεση με τον διακομιστή…",
  "Updating Content": "Ενημέρωση περιεχομένου",
  "{done} / {total} categories": "{done} / {total} κατηγορίες",
  "This happens every few days to keep your catalog current — everyday launches open straight in.":
      "Γίνεται κάθε λίγες μέρες για να μένει ο κατάλογος ενημερωμένος — τις άλλες μέρες η εφαρμογή ανοίγει αμέσως.",
  "Re-checks every visible category for new content. This can take a few minutes on a large catalog.":
      "Ελέγχει ξανά κάθε ορατή κατηγορία για νέο περιεχόμενο. Σε μεγάλο κατάλογο μπορεί να πάρει λίγα λεπτά.",
  "Cancel": "Άκυρο",
  "Multiview": "Multiview",
  "Layout": "Διάταξη",
  "2 channels": "2 κανάλια",
  "4 channels": "4 κανάλια",
  "= audio — click a channel to switch": "= ήχος · κλικ σε κανάλι για αλλαγή",
  "Reload": "Επαναφόρτωση",
  "Change channel": "Αλλαγή καναλιού",
  "Remove": "Αφαίρεση",
  "Search channels...": "Αναζήτηση καναλιών…",
  "Before you start": "Πριν ξεκινήσετε",
  "Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn't, press OK on it and choose Reload.":
      "Κάθε οθόνη του Multiview είναι ξεχωριστή σύνδεση με τον πάροχό σας. Η λίστα σας πρέπει να επιτρέπει τουλάχιστον τόσες συνδέσεις όσες οθόνες ανοίγετε (δείτε Μέγιστες συνδέσεις στη Διαχείριση λιστών).\n\nΑν δύο οθόνες μοιράζονται λογαριασμό που επιτρέπει μόνο μία σύνδεση, διώχνουν η μία την άλλη και παγώνουν ή φορτώνουν συνέχεια. Συμβουλή: χρησιμοποιήστε κανάλια από διαφορετικές λίστες, μία ανά λογαριασμό.\n\nΜια οθόνη που παγώνει ξεκινά ξανά μόνη της. Αν όχι, πατήστε OK πάνω της και επιλέξτε Επαναφόρτωση.",
  "Don't show this again": "Να μην εμφανιστεί ξανά",
  "OK": "OK",
  "Couldn't start that channel": "Δεν ήταν δυνατή η έναρξη του καναλιού",
  "Full screen": "Πλήρης οθόνη",
  "Windowed": "Σε παράθυρο",
  "4 screens": "4 οθόνες",
  "1 + 3 screens": "1 + 3 οθόνες",
  "Move to the big screen": "Στη μεγάλη οθόνη",
  "Swap mode": "Λειτουργία εναλλαγής",
  "SWAP": "ΕΝΑΛΛΑΓΗ",
  "Arrows swap · OK or Back to finish": "Βέλη: εναλλαγή · OK ή Πίσω: τέλος",
  "2 screens": "2 οθόνες",
  "= audio — Select to switch, hold Select for options":
      "= ήχος · OK για αλλαγή, κρατήστε το OK για επιλογές",
  "Pick a channel": "Επιλέξτε κανάλι",
  "No channels found": "Δεν βρέθηκαν κανάλια",
  "Open in Multiview": "Άνοιγμα σε Multiview",
  "Recall — recently watched": "Πρόσφατα — όσα είδατε πρόσφατα",
  "No other live channels watched yet this session.":
      "Δεν έχετε δει άλλα ζωντανά κανάλια σε αυτή τη συνεδρία.",
  "Recall — go back to a recent channel":
      "Πρόσφατα — επιστροφή σε πρόσφατο κανάλι",
  "Remove from favorites": "Αφαίρεση από τα αγαπημένα",
  "Add to favorites": "Προσθήκη στα αγαπημένα",
  "Reload channel": "Επαναφόρτωση καναλιού",
  "Previous episode": "Προηγούμενο επεισόδιο",
  "Next episode": "Επόμενο επεισόδιο",
  "Ending now": "Τελειώνει τώρα",
  "{minutes} min left": "Απομένουν {minutes} λεπτά",
  "Back": "Πίσω",
  "Fit to screen": "Προσαρμογή στην οθόνη",
  "Fill screen": "Γέμισμα οθόνης",
  "Closed captions (CC) — if the channel broadcasts them":
      "Υπότιτλοι για κωφούς (CC) — αν τους μεταδίδει το κανάλι",
  "Up Next": "Στη συνέχεια",
  "Playing in {countdown}s": "Αναπαραγωγή σε {countdown} δ",
  "Playing now...": "Αναπαραγωγή τώρα…",
  "Play now": "Αναπαραγωγή τώρα",
  "Dismiss": "Απόρριψη",
  "Select a channel to start watching": "Επιλέξτε ένα κανάλι για να ξεκινήσετε",
  "Switch to {p}: {name}": "Αλλαγή σε {p}: {name}",
  "Switch to {playlistName}: {name}": "Αλλαγή σε {playlistName}: {name}",
  "Technical details": "Τεχνικές λεπτομέρειες",
  "This is a Dolby Vision video, and this device can't play this kind of Dolby Vision. Pick a version without DV (HDR10 or SDR) if your source has one.":
      "Αυτό το βίντεο είναι Dolby Vision και αυτή η συσκευή δεν μπορεί να παίξει αυτό το είδος Dolby Vision. Διάλεξε μια έκδοση χωρίς DV (HDR10 ή SDR) αν την προσφέρει η πηγή σου.",
  "This stream kept dropping and restarting, so playback was stopped. Try the channel again in a moment, or pick another one.":
      "Αυτή η ροή διακοπτόταν και ξεκινούσε ξανά συνεχώς, οπότε η αναπαραγωγή σταμάτησε. Δοκιμάστε ξανά το κανάλι σε λίγο ή επιλέξτε άλλο.",
  "This device's video decoder couldn't play this stream — likely 4K HDR (HEVC 10-bit). If your provider offers an HD (non-4K) version of this channel or title, try that. If another app plays this stream on this device, please report it with a photo of the technical details below.":
      "Ο αποκωδικοποιητής βίντεο της συσκευής δεν μπόρεσε να παίξει αυτή τη ροή — πιθανότατα 4K HDR (HEVC 10-bit). Αν ο πάροχος έχει έκδοση HD (όχι 4K) αυτού του καναλιού ή τίτλου, δοκιμάστε την. Αν άλλη εφαρμογή παίζει αυτή τη ροή σε αυτή τη συσκευή, αναφέρετέ το με φωτογραφία των τεχνικών λεπτομερειών παρακάτω.",
  "Playback error:\n{raw}": "Σφάλμα αναπαραγωγής:\n{raw}",
  "Server error {code}": "Σφάλμα διακομιστή {code}",
  "The provider's server had a problem. Try again in a moment.":
      "Ο διακομιστής του παρόχου είχε πρόβλημα. Δοκιμάστε ξανά σε λίγο.",
  "The provider refused the stream: check that your account is active and not already in use on another device.":
      "Ο πάροχος αρνήθηκε τη ροή: ελέγξτε ότι ο λογαριασμός σας είναι ενεργός και δεν χρησιμοποιείται ήδη σε άλλη συσκευή.",
  "The provider has no stream at this address: the channel or title may have been removed.":
      "Ο πάροχος δεν έχει ροή σε αυτή τη διεύθυνση: το κανάλι ή ο τίτλος μπορεί να έχει αφαιρεθεί.",
  "The provider rejected the request.": "Ο πάροχος απέρριψε το αίτημα.",
  "Couldn't reach the provider's server. Check your internet connection, or the server may be down.":
      "Δεν ήταν δυνατή η σύνδεση με τον διακομιστή του παρόχου. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο, ή ο διακομιστής μπορεί να είναι εκτός λειτουργίας.",
  "Couldn't find the provider's server address. Check your internet connection or DNS settings, or try again later.":
      "Δεν ήταν δυνατός ο εντοπισμός της διεύθυνσης του διακομιστή του παρόχου. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο ή τις ρυθμίσεις DNS και δοκιμάστε ξανά αργότερα.",
  "Subtitles": "Υπότιτλοι",
  "1 game": "1 αγώνας",
  "{live} live": "{live} ζωντανά",
  "Leagues with games": "Πρωταθλήματα με αγώνες",
  "All leagues": "Όλα τα πρωταθλήματα",
  "{n} games": "{n} αγώνες",
  "{n} games · {live} live": "{n} αγώνες · {live} ζωντανά",
  "No games": "Χωρίς αγώνες",
  "Favourite networks": "Αγαπημένα δίκτυα",
  "Favourite this network": "Προσθήκη δικτύου στα αγαπημένα",
  "Remove from favourite networks": "Αφαίρεση από τα αγαπημένα δίκτυα",
  "Networks": "Δίκτυα",
  "Other sports channels": "Άλλα αθλητικά κανάλια",
  "On now": "Τώρα",
  "No channel matches these filters.":
      "Κανένα κανάλι δεν ταιριάζει με αυτά τα φίλτρα.",
  "No sports channels found in your playlists.":
      "Δεν βρέθηκαν αθλητικά κανάλια στις λίστες σας.",
  "Empty list: hold OK on any channel card to add it here.":
      "Κενή λίστα: κρατήστε OK σε μια κάρτα καναλιού για να την προσθέσετε εδώ.",
  "OK · Full screen   Hold OK · Pick a channel   Back · Stop":
      "OK · Πλήρης οθόνη   Κράτημα OK · Επιλογή καναλιού   Πίσω · Διακοπή",
  "OK · Preview   Hold OK · Pick a channel or add to a list":
      "OK · Προεπισκόπηση   Κράτημα OK · Επιλογή καναλιού ή προσθήκη σε λίστα",
  "See all": "Όλα",
  "Update automatically": "Αυτόματη ενημέρωση",
  "Live stream format: HLS": "Μορφή ζωντανής ροής: HLS",
  "Off: MPEG-TS (default, fastest start). On: HLS, like the HLS option in TiviMate. Plays about 10 seconds further behind live, but hides servers that send live TV in bursts. Applies from the next channel.": "Ανενεργό: MPEG-TS (προεπιλογή, γρηγορότερη εκκίνηση). Ενεργό: HLS, όπως η επιλογή HLS του TiviMate. Παίζει περίπου 10 δευτερόλεπτα πιο πίσω από το ζωντανό, αλλά κρύβει διακομιστές που στέλνουν τη ζωντανή TV κατά ριπές. Ισχύει από το επόμενο κανάλι.",
  "On: when an update is due, it runs at launch without asking. Off: the app asks \"Update content now?\" first.":
      "Ενεργό: όταν οφείλεται ενημέρωση, γίνεται στην εκκίνηση χωρίς ερώτηση. Ανενεργό: η εφαρμογή ρωτά πρώτα «Ενημέρωση περιεχομένου τώρα;».",
  "Open on": "Άνοιγμα σε",
  "{section}. Where the app opens after starting. With \"Resume last channel in full screen\" on, the channel then plays in the background instead.":
      "{section}. Πού ανοίγει η εφαρμογή στην εκκίνηση. Με ενεργή τη «Συνέχιση τελευταίου καναλιού σε πλήρη οθόνη», το κανάλι παίζει τότε στο παρασκήνιο.",
  "Subtitle size": "Μέγεθος υποτίτλων",
  "Enter a name first": "Γράψτε πρώτα ένα όνομα",
  "Dolby Vision (profile {p}, no HDR10 fallback)":
      "Dolby Vision (προφίλ {p}, χωρίς εναλλακτικό HDR10)",
  "Dolby Vision (profile {p}, HDR10 compatible)":
      "Dolby Vision (προφίλ {p}, συμβατό με HDR10)",
  "Dolby Vision (profile {p}, HLG compatible)":
      "Dolby Vision (προφίλ {p}, συμβατό με HLG)",
  "Dolby Vision (profile {p})": "Dolby Vision (προφίλ {p})",
  "Extra small": "Πολύ μικρό",
  "Small": "Μικρό",
  "Normal": "Κανονικό",
  "Large": "Μεγάλο",
  "Extra large": "Πολύ μεγάλο",
  "Off": "Ανενεργό",
  "Forced": "Υποχρεωτικοί",
  "Online": "Online",
  "Search online subtitles": "Αναζήτηση υποτίτλων online",
  "From your add-ons (Settings > Add-ons)":
      "Από τα πρόσθετά σας (Ρυθμίσεις > Πρόσθετα)",
  "Online subtitles": "Υπότιτλοι online",
  "No subtitles found for this title.":
      "Δεν βρέθηκαν υπότιτλοι για αυτόν τον τίτλο.",
  "Couldn't download that subtitle. Try another.":
      "Δεν ήταν δυνατή η λήψη αυτών των υποτίτλων. Δοκιμάστε άλλους.",
  "Add-ons": "Πρόσθετα",
  "Online subtitles in more languages":
      "Υπότιτλοι online σε περισσότερες γλώσσες",
  "Remove {name}?": "Αφαίρεση του {name};",
  "That link isn't a subtitle add-on (only subtitle add-ons are supported).":
      "Αυτός ο σύνδεσμος δεν είναι πρόσθετο υποτίτλων (υποστηρίζονται μόνο πρόσθετα υποτίτλων).",
  "That add-on is already in the list.":
      "Αυτό το πρόσθετο είναι ήδη στη λίστα.",
  "{name} added.": "Προστέθηκε το {name}.",
  "Add-ons find subtitles online for movies and episodes, in many languages. They are free community services, separate from your provider — VesperTV only uses them for subtitles. Turn one on, then pick \"Search online subtitles\" in the player's Subtitles button.":
      "Τα πρόσθετα βρίσκουν υπότιτλους online για ταινίες και επεισόδια, σε πολλές γλώσσες. Είναι δωρεάν υπηρεσίες της κοινότητας, ανεξάρτητες από τον πάροχό σας — το VesperTV τα χρησιμοποιεί μόνο για υπότιτλους. Ενεργοποιήστε ένα και μετά επιλέξτε «Αναζήτηση υποτίτλων online» στο κουμπί Υπότιτλοι του player.",
  "Subtitle add-ons": "Πρόσθετα υποτίτλων",
  "Subtitles in 60+ languages from OpenSubtitles.org":
      "Υπότιτλοι σε 60+ γλώσσες από το OpenSubtitles.org",
  "Hold OK to remove": "Κρατήστε το OK για αφαίρεση",
  "Add an add-on": "Προσθήκη πρόσθετου",
  "Add-on link (ends with manifest.json)":
      "Σύνδεσμος πρόσθετου (τελειώνει σε manifest.json)",
  "Only subtitle add-ons work here. When one is on, the title and episode you are watching are sent to it to find subtitles; nothing else is shared.":
      "Εδώ λειτουργούν μόνο πρόσθετα υποτίτλων. Όταν ένα είναι ενεργό, του στέλνεται ο τίτλος και το επεισόδιο που βλέπετε για να βρει υπότιτλους· τίποτα άλλο δεν κοινοποιείται.",
  "Looking for {language} subtitles…": "Αναζήτηση υποτίτλων {language}…",
  "No {language} subtitles for this title.":
      "Δεν υπάρχουν υπότιτλοι {language} για αυτόν τον τίτλο.",
  "No {language} subtitles online for this title.":
      "Δεν υπάρχουν υπότιτλοι {language} online για αυτόν τον τίτλο.",
  "Track {id}": "Κομμάτι {id}",
  "Audio {n}": "Ήχος {n}",
  "Audio Track": "Κομμάτι ήχου",
  "Audio track": "Κομμάτι ήχου",
  "Sort": "Ταξινόμηση",
  "Default": "Προεπιλογή",
  "A to Z": "Α έως Ω",
  "Z to A": "Ω έως Α",
  "Rating (high to low)": "Βαθμολογία (από υψηλή)",
  "Date added/updated": "Ημερομηνία προσθήκης/ενημέρωσης",
  "Fetching TMDB release dates... {done}/{total}":
      "Λήψη ημερομηνιών κυκλοφορίας από TMDB… {done}/{total}",
  "Added to Favorites": "Προστέθηκε στα Αγαπημένα",
  "Removed from Favorites": "Αφαιρέθηκε από τα Αγαπημένα",
  "No items in this group.": "Δεν υπάρχουν στοιχεία σε αυτή την ομάδα.",
  "Re-checks your M3U playlist URL(s) for new content.":
      "Ελέγχει ξανά τα URL της λίστας M3U για νέο περιεχόμενο.",
  "Set your playlist source in Settings first.":
      "Ορίστε πρώτα την πηγή της λίστας σας στις Ρυθμίσεις.",
  "Continue Watching": "Συνέχεια παρακολούθησης",
  "Search": "Αναζήτηση",
  "Update content": "Ενημέρωση περιεχομένου",
  "Update EPG now": "Ενημέρωση EPG τώρα",
  "Settings": "Ρυθμίσεις",
  "No TV shows found. Pick a category on the left.":
      "Δεν βρέθηκαν σειρές. Επιλέξτε κατηγορία αριστερά.",
  "No channels found.": "Δεν βρέθηκαν κανάλια.",
  "Loading playlist...": "Φόρτωση λίστας…",
  "Failed to load playlist.": "Η φόρτωση της λίστας απέτυχε.",
  "Open Settings": "Άνοιγμα Ρυθμίσεων",
  "{p}% watched": "Παρακολουθήθηκε {p}%",
  "Resume": "Συνέχεια",
  "Play": "Αναπαραγωγή",
  "Restart": "Από την αρχή",
  "Failed to load episodes.": "Η φόρτωση των επεισοδίων απέτυχε.",
  "No episodes found.": "Δεν βρέθηκαν επεισόδια.",
  "Season {season}": "Σεζόν {season}",
  "Expand catalog": "Επέκταση καταλόγου",
  "Browse": "Περιήγηση",
  "Playlist": "Λίστα",
  "Previous": "Προηγούμενο",
  "Next": "Επόμενο",
  "Loading...": "Φόρτωση…",
  "Loading…": "Φόρτωση…",
  "No recently added movies yet": "Δεν υπάρχουν ακόμη πρόσφατες ταινίες",
  "Loading movie categories...": "Φόρτωση κατηγοριών ταινιών…",
  "No recently added shows yet": "Δεν υπάρχουν ακόμη πρόσφατες σειρές",
  "Loading TV show categories...": "Φόρτωση κατηγοριών σειρών…",
  "What's New": "Τι νέο υπάρχει",
  "Switch Profile": "Αλλαγή προφίλ",
  "Restricted": "Περιορισμένο",
  "Search everything...": "Αναζήτηση παντού…",
  "Search everything... (press OK to type)":
      "Αναζήτηση παντού… (πατήστε OK για πληκτρολόγηση)",
  "Still loading the full catalog in the background ({warmCatalogDone}/{warmCatalogTotal} categories) — some results may not show up yet.":
      "Ο πλήρης κατάλογος φορτώνει ακόμη στο παρασκήνιο ({warmCatalogDone}/{warmCatalogTotal} κατηγορίες) — ορισμένα αποτελέσματα μπορεί να μην εμφανίζονται ακόμη.",
  "Search Live TV, Movies & TV Shows":
      "Αναζήτηση σε Ζωντανή TV, Ταινίες και Σειρές",
  "Recent searches": "Πρόσφατες αναζητήσεις",
  "Clear": "Καθαρισμός",
  "Live TV": "Ζωντανή TV",
  "Movies": "Ταινίες",
  "TV Shows": "Σειρές",
  "Nothing found": "Δεν βρέθηκε τίποτα",
  "Sports": "Αθλητικά",
  "this team": "αυτή η ομάδα",
  "My Teams": "Οι ομάδες μου",
  "Last channels": "Τελευταία κανάλια",
  "◀ ▶ tabs  ·  OK to watch  ·  Back to close":
      "◀ ▶ καρτέλες  ·  OK για προβολή  ·  Πίσω για κλείσιμο",
  "None of your teams play today.":
      "Καμία από τις ομάδες σας δεν παίζει σήμερα.",
  "Follow teams from {tab} > Standings to see them here.":
      "Ακολουθήστε ομάδες από {tab} > Βαθμολογίες για να εμφανίζονται εδώ.",
  "No games from your leagues are live right now.":
      "Κανένα παιχνίδι από τα πρωταθλήματά σας δεν είναι ζωντανά τώρα.",
  "Hold OK on a team to unfollow · on a game to pick the channel":
      "Κρατήστε το OK σε ομάδα για κατάργηση παρακολούθησης · σε παιχνίδι για επιλογή καναλιού",
  "Add team": "Προσθήκη ομάδας",
  "Follow one from Standings": "Ακολουθήστε μία από τις Βαθμολογίες",
  "Could not load": "Δεν φορτώθηκε",
  "Follow your teams to see them here":
      "Ακολουθήστε τις ομάδες σας για να εμφανίζονται εδώ",
  "Follow another team": "Ακολουθήστε άλλη ομάδα",
  "Add team opens Standings: hold OK on a team to follow it.":
      "Η Προσθήκη ομάδας ανοίγει τις Βαθμολογίες: κρατήστε το OK σε μια ομάδα για να την ακολουθήσετε.",
  "This team could not be loaded. Check the connection.":
      "Δεν ήταν δυνατή η φόρτωση της ομάδας. Ελέγξτε τη σύνδεση.",
  "Next 2 weeks": "Επόμενες 2 εβδομάδες",
  "No games in the next two weeks.":
      "Κανένα παιχνίδι τις επόμενες δύο εβδομάδες.",
  "vs": "vs",
  "at": "στην έδρα της",
  "Today {time}": "Σήμερα {time}",
  "Tomorrow {time}": "Αύριο {time}",
  "Last game: {opponent} · Final": "Τελευταίο παιχνίδι: {opponent} · Τελικό",
  "Last game: {result} {mine}-{other} {opponent}":
      "Τελευταίο παιχνίδι: {result} {mine}-{other} {opponent}",
  "LIVE": "ΖΩΝΤΑΝΑ",
  "Looking…": "Αναζήτηση…",
  "TEAM": "ΟΜΑΔΑ",
  "Later today": "Αργότερα σήμερα",
  "Tomorrow": "Αύριο",
  "Not played": "Δεν έγινε",
  "Scheduled": "Προγραμματισμένο",
  "Live now": "Ζωντανά τώρα",
  "Final": "Τελικό",
  "All": "Όλα",
  "Edit leagues": "Επεξεργασία πρωταθλημάτων",
  "Scores hidden": "Σκορ κρυφά",
  "Scores shown": "Σκορ ορατά",
  "Yesterday": "Χθες",
  "Today": "Σήμερα",
  "Day": "Ημέρα",
  'OK: watch  ·  OK again: full screen  ·  Hold OK: stats  ·  ▼ all games':
      "OK: παρακολούθηση  ·  OK ξανά: πλήρης οθόνη  ·  Κράτημα OK: στατιστικά  ·  ▼ όλοι οι αγώνες",
  'OK again on a game: full screen  ·  ▶❚❚: stop':
      "OK ξανά σε αγώνα: πλήρης οθόνη  ·  ▶❚❚: διακοπή",
  "Standings": "Βαθμολογίες",
  "{name} standings": "Βαθμολογία {name}",
  "{name} championship": "Πρωτάθλημα {name}",
  "No games on this day for your leagues":
      "Κανένα παιχνίδι αυτή τη μέρα στα πρωταθλήματά σας",
  "Try another day, or add leagues with Edit leagues.":
      "Δοκιμάστε άλλη μέρα ή προσθέστε πρωταθλήματα από την Επεξεργασία πρωταθλημάτων.",
  "Live now  {count}": "Ζωντανά τώρα  {count}",
  "Live": "Ζωντανά",
  "Starts in {p}{p2}m": "Ξεκινά σε {p}{p2}λ",
  "Looking for the channel…": "Αναζήτηση καναλιού…",
  "No channel found — OK to pick one": "Δεν βρέθηκε κανάλι — OK για επιλογή",
  "Hold OK to pick or swap the channel":
      "Κρατήστε το OK για επιλογή ή αλλαγή καναλιού",
  "Hold OK: pick the channel  ·  ▶❚❚: watch here":
      "Κρατήστε το OK: επιλογή καναλιού  ·  ▶❚❚: προβολή εδώ",
  "Tap the game again: full screen  ·  Back: stop":
      "Πατήστε ξανά το παιχνίδι: πλήρης οθόνη  ·  Πίσω: διακοπή",
  "Tap: watch here  ·  Hold: pick the channel":
      "Πάτημα: προβολή εδώ  ·  Παρατεταμένο: επιλογή καναλιού",
  "Play here": "Προβολή εδώ",
  "{channel} · plays at the top of {tab}":
      "{channel} · παίζει στην κορυφή του {tab}",
  "▶❚❚: watch this game  ·  Back: playing game":
      "▶❚❚: δείτε αυτό το παιχνίδι  ·  Πίσω: το παιχνίδι που παίζει",
  "OK: full screen  ·  ▶❚❚ or Back: stop":
      "OK: πλήρης οθόνη  ·  ▶❚❚ ή Πίσω: διακοπή",
  "Still looking for channels…": "Αναζήτηση καναλιών ακόμη…",
  "No channel found for this game": "Δεν βρέθηκε κανάλι για αυτό το παιχνίδι",
  "On {matches} channel{s}": "Σε {matches} κανάλια",
  "Pick the channel": "Επιλογή καναλιού",
  "Choose a different channel": "Επιλέξτε άλλο κανάλι",
  "Search your channels — it can be remembered for this game or team":
      "Αναζητήστε στα κανάλια σας — μπορεί να απομνημονευτεί για αυτό το παιχνίδι ή την ομάδα",
  "Forget my pick": "Ξεχάστε την επιλογή μου",
  "Go back to the automatic match": "Επιστροφή στην αυτόματη αντιστοίχιση",
  "Remember this channel?": "Να απομνημονευτεί αυτό το κανάλι;",
  "Just this game": "Μόνο για αυτό το παιχνίδι",
  "Best for channels named after one game":
      "Καλύτερο για κανάλια με όνομα ενός παιχνιδιού",
  "Always for the {shortName}": "Πάντα για {shortName}",
  "Best for a regular channel, like a regional network":
      "Καλύτερο για κανονικό κανάλι, όπως ένα περιφερειακό δίκτυο",
  "Leagues": "Πρωταθλήματα",
  "Save": "Αποθήκευση",
  "Pick the channel for {title}": "Επιλέξτε το κανάλι για {title}",
  "Search channels": "Αναζήτηση καναλιών",
  "No channels match \"{query}\"": "Κανένα κανάλι δεν ταιριάζει με «{query}»",
  "{results}{p} channels": "{results}{p} κανάλια",
  "{group} · Now: {now}": "{group} · Τώρα: {now}",
  "Preseason": "Προετοιμασία",
  "Pick a league above, then hold OK on a team to follow it. Back returns to My Teams.":
      "Επιλέξτε ένα πρωτάθλημα παραπάνω και κρατήστε το OK σε μια ομάδα για να την ακολουθήσετε. Το Πίσω επιστρέφει στις Ομάδες μου.",
  "Standings could not be loaded. Check the connection.":
      "Δεν ήταν δυνατή η φόρτωση των βαθμολογιών. Ελέγξτε τη σύνδεση.",
  "switch conference": "αλλαγή περιφέρειας",
  "switch table": "αλλαγή πίνακα",
  "Hold OK on a team to follow it (My Teams)":
      "Κρατήστε το OK σε μια ομάδα για να την ακολουθήσετε (Οι ομάδες μου)",
  "Your pick": "Η επιλογή σας",
  "Found by its name": "Βρέθηκε από το όνομα",
  "Found in the guide": "Βρέθηκε στον οδηγό",
  "Team's channel, no guide listing":
      "Κανάλι της ομάδας, χωρίς καταχώριση στον οδηγό",
  "Broadcaster, no guide listing":
      "Κανάλι μετάδοσης, χωρίς καταχώριση στον οδηγό",
  "Only on a hidden channel": "Μόνο σε κρυφό κανάλι",
  "Not in your guide yet": "Δεν είναι ακόμα στον οδηγό σου",
  "On a hidden channel — OK to pick one":
      "Σε κρυφό κανάλι — OK για να διαλέξεις ένα",
  "Not in your guide yet — OK to pick one":
      "Δεν είναι ακόμα στον οδηγό σου — OK για να διαλέξεις ένα",
  "Only found on {channel}, which is hidden in your lists.":
      "Βρέθηκε μόνο στο {channel}, που είναι κρυφό στις λίστες σου.",
  "Your guide doesn't cover this game's time yet. Update the guide closer to the game.":
      "Ο οδηγός σου δεν καλύπτει ακόμα την ώρα αυτού του αγώνα. Ενημέρωσε τον οδηγό πιο κοντά στον αγώνα.",
  "No channel name or guide listing names this game.":
      "Κανένα όνομα καναλιού ή πρόγραμμα του οδηγού δεν αναφέρει αυτόν τον αγώνα.",
  "Some scores could not be loaded. Check the connection.":
      "Ορισμένα σκορ δεν φορτώθηκαν. Ελέγξτε τη σύνδεση.",
  "Unfollow": "Κατάργηση παρακολούθησης",
  "Follow": "Παρακολούθηση",
  "Remove from My Teams": "Αφαίρεση από τις Ομάδες μου",
  "Add to My Teams — their games show first in {tab}":
      "Προσθήκη στις Ομάδες μου — τα παιχνίδια τους εμφανίζονται πρώτα στο {tab}",
  "W": "Ν",
  "L": "Η",
  "D": "Ι",
  "T": "Ι",
  "GP": "ΑΓ",
  "GD": "ΔΤ",
  "PTS": "ΒΑΘ",
  "OTL": "ΗΠ",
  "DIFF": "ΔΙΑΦ",
  "STRK": "ΣΕΡΙ",
  "L10": "Τ10",
  "REC": "ΡΕΚ",
  "PF": "ΥΠ",
  "PA": "ΚΑΤ",
  "HOME": "ΕΝΤΟΣ",
  "AWAY": "ΕΚΤΟΣ",
  "PCT": "%",
  "GB": "ΠΙΣΩ",
  "TV": "TV",
  "Favorites": "Αγαπημένα",
  "Favourites": "Αγαπημένα",
  "Remove from Favourites": "Αφαίρεση από τα Αγαπημένα",
  "Add to Favourites": "Προσθήκη στα Αγαπημένα",
  "Cancel Hide": "Ακύρωση απόκρυψης",
  "Hide Group": "Απόκρυψη ομάδας",
  "Move Up / Down": "Μετακίνηση πάνω / κάτω",
  "Show": "Εμφάνιση",
  "Hide": "Απόκρυψη",
  "Hidden here · {n} groups": "Κρυμμένες εδώ · {n} ομάδες",
  "At least one playlist stays shown.": "Τουλάχιστον μία λίστα μένει ορατή.",
  "{name} hidden in {tab}": "Η {name} κρύφτηκε στο {tab}",
  "{name} shown in {tab}": "Η {name} εμφανίζεται στο {tab}",
  "Playlists": "Λίστες",
  "Jump to playlist": "Μετάβαση σε λίστα",
  "{n} groups": "{n} ομάδες",
  "Background video": "Βίντεο στο παρασκήνιο",
  "Mute": "Σίγαση",
  "Unmute": "Κατάργηση σίγασης",
  "Show under Other": "Εμφάνιση στο Άλλο",
  "On: this source only appears behind the Other genre filter (Movies and TV Shows). Off: in the main rows. Press Refresh in Media Hub after changing this.":
      "Ενεργό: αυτή η πηγή εμφανίζεται μόνο πίσω από το φίλτρο είδους Άλλο (Ταινίες και Σειρές). Ανενεργό: στις κύριες σειρές. Πατήστε Ανανέωση στο Media Hub μετά την αλλαγή.",
  "Use the Other filter in Media Hub > Movies / TV Shows > Genre to see this source.":
      "Χρησιμοποιήστε το φίλτρο Άλλο στο Media Hub > Ταινίες / Σειρές > Είδος για να δείτε αυτή την πηγή.",
  "Back to main": "Επιστροφή στα κύρια",
  "Compatibility video": "Συμβατό βίντεο",
  "Turn this on if the picture shows twice, in the wrong size or as coloured stripes (older Fire TV sticks). Applies from the next channel. On by default on Android 7 and older.":
      "Ενεργοποιήστε το αν η εικόνα εμφανίζεται διπλή, σε λάθος μέγεθος ή με χρωματιστές ρίγες (παλαιότερα Fire TV stick). Ισχύει από το επόμενο κανάλι. Ενεργό από προεπιλογή σε Android 7 και παλαιότερα.",
  "Hide the live picture behind other pages":
      "Απόκρυψη της ζωντανής εικόνας πίσω από άλλες σελίδες",
  "A live channel keeps playing behind {tab}, Settings and Search. Some Fire TV sticks keep showing its picture on top of those pages. Turn this on if that happens: the sound keeps going, only the picture is hidden until you go back. Updating the device's software (Fire TV: Settings > My Fire TV > About > Check for Updates) may fix it too.":
      "Ένα ζωντανό κανάλι συνεχίζει να παίζει πίσω από {tab}, Ρυθμίσεις και Αναζήτηση. Ορισμένα Fire TV stick συνεχίζουν να δείχνουν την εικόνα του πάνω από αυτές τις σελίδες. Ενεργοποιήστε το αν συμβαίνει αυτό: ο ήχος συνεχίζει, μόνο η εικόνα κρύβεται μέχρι να επιστρέψετε. Η ενημέρωση του λογισμικού της συσκευής (Fire TV: Ρυθμίσεις > My Fire TV > About > Check for Updates) μπορεί επίσης να το διορθώσει.",
  "Go to row": "Μετάβαση σε σειρά",
  "Typing a server address and password with a remote is painful. Scan this code with your phone camera and sign in there — the details appear here for you to check and connect.":
      "Η πληκτρολόγηση διεύθυνσης διακομιστή και κωδικού με τηλεχειριστήριο είναι κουραστική. Σαρώστε αυτόν τον κωδικό με την κάμερα του κινητού σας και συνδεθείτε εκεί — τα στοιχεία εμφανίζονται εδώ για έλεγχο και σύνδεση.",
  "Check the details here, then press Connect.":
      "Ελέγξτε τα στοιχεία εδώ και πατήστε Σύνδεση.",
  "{n} other catalogs": "{n} άλλοι κατάλογοι",
  "Use the Other filter in Media Hub > Movies > Genre to see this content.":
      "Χρησιμοποιήστε το φίλτρο Άλλο στο Media Hub > Ταινίες > Είδος για να δείτε αυτό το περιεχόμενο.",
  "Backup & restore": "Αντίγραφα ασφαλείας και επαναφορά",
  "Save everything to a file on this device":
      "Αποθήκευση όλων σε αρχείο σε αυτή τη συσκευή",
  "Back up now": "Αντίγραφο ασφαλείας τώρα",
  "Playlists, favourites, profiles, progress and settings, saved to {path}":
      "Λίστες, αγαπημένα, προφίλ, πρόοδος και ρυθμίσεις, αποθηκευμένα στο {path}",
  "Automatic backup": "Αυτόματο αντίγραφο ασφαλείας",
  "Once a week, when VesperTV starts. Keeps the last {n}.":
      "Μία φορά την εβδομάδα, όταν ξεκινά το VesperTV. Κρατά τα τελευταία {n}.",
  "Restore from a file": "Επαναφορά από αρχείο",
  "Pick a backup file, e.g. after reinstalling VesperTV":
      "Επιλέξτε ένα αρχείο αντιγράφου, π.χ. μετά από επανεγκατάσταση του VesperTV",
  "Backups": "Αντίγραφα ασφαλείας",
  "No backups yet.": "Δεν υπάρχουν ακόμη αντίγραφα.",
  "Backups include your playlist logins. Keep the files private.":
      "Τα αντίγραφα περιέχουν τα στοιχεία σύνδεσης των λιστών σας. Κρατήστε τα αρχεία ιδιωτικά.",
  "Manual": "Χειροκίνητο",
  "Restore this backup": "Επαναφορά αυτού του αντιγράφου",
  "Restore": "Επαναφορά",
  "Restore backup?": "Επαναφορά αντιγράφου;",
  "Everything on this device (playlists, favourites, profiles, settings) is replaced by the backup from {from}. Your current setup is saved as an automatic backup first. VesperTV closes afterwards.":
      "Όλα σε αυτή τη συσκευή (λίστες, αγαπημένα, προφίλ, ρυθμίσεις) αντικαθίστανται από το αντίγραφο της {from}. Η τρέχουσα ρύθμιση αποθηκεύεται πρώτα ως αυτόματο αντίγραφο. Το VesperTV κλείνει μετά.",
  "the chosen file": "το επιλεγμένο αρχείο",
  "Backup restored": "Το αντίγραφο επαναφέρθηκε",
  "Backup saved to {path}": "Το αντίγραφο αποθηκεύτηκε στο {path}",
  "Backup failed: {error}": "Το αντίγραφο ασφαλείας απέτυχε: {error}",
  "VesperTV needs storage access to save backups.":
      "Το VesperTV χρειάζεται πρόσβαση στον αποθηκευτικό χώρο για να αποθηκεύει αντίγραφα.",
  "Couldn't read the backup folder: {error}":
      "Δεν ήταν δυνατή η ανάγνωση του φακέλου αντιγράφων: {error}",
  "Couldn't read this backup: {error}":
      "Δεν ήταν δυνατή η ανάγνωση αυτού του αντιγράφου: {error}",
  "Couldn't delete this backup.":
      "Δεν ήταν δυνατή η διαγραφή αυτού του αντιγράφου.",
  "This device has no file picker. Copy the backup into {path} on this device instead.":
      "Αυτή η συσκευή δεν έχει επιλογέα αρχείων. Αντιγράψτε το αντίγραφο στο {path} αυτής της συσκευής.",
  "This file is not a VesperTV backup.":
      "Αυτό το αρχείο δεν είναι αντίγραφο ασφαλείας του VesperTV.",
  "Up / Down moves {name}. OK when done.":
      "Πάνω / Κάτω μετακινεί το {name}. OK όταν τελειώσετε.",
  "Mix playlists in Favourites": "Ανάμειξη λιστών στα Αγαπημένα",
  "TV, Movies and TV Shows favourites from every playlist in one A-Z list, instead of one list per playlist.":
      "Αγαπημένα TV, Ταινιών και Σειρών από κάθε λίστα σε μία λίστα Α-Ω, αντί για μία λίστα ανά λίστα.",
  "Move to Top": "Μετακίνηση στην κορυφή",
  "Unhide this channel": "Επανεμφάνιση αυτού του καναλιού",
  "Hide this channel": "Απόκρυψη αυτού του καναλιού",
  "Double": "Διπλό",
  "for groups": "για ομάδες",
  "Exit and free up this login?": "Έξοδος και αποδέσμευση αυτής της σύνδεσης;",
  "This disconnects your login here so it can be used on another device, then fully closes VesperTV. Your channels/movies will need to reload next time you open it.":
      "Αποσυνδέει τη σύνδεσή σας εδώ ώστε να χρησιμοποιηθεί σε άλλη συσκευή και μετά κλείνει εντελώς το VesperTV. Τα κανάλια/ταινίες θα χρειαστεί να φορτώσουν ξανά την επόμενη φορά.",
  "Exit": "Έξοδος",
  "Exit {appName}?": "Έξοδος από το {appName};",
  "Are you sure you want to exit {appName}?":
      "Θέλετε σίγουρα να βγείτε από το {appName};",
  "Stay": "Παραμονή",
  "History": "Ιστορικό",
  "No channels watched yet.": "Δεν έχετε δει ακόμη κανάλια.",
  "Update Content": "Ενημέρωση περιεχομένου",
  "Minimize": "Ελαχιστοποίηση",
  "Close": "Κλείσιμο",
  "Disable and exit": "Απενεργοποίηση και έξοδος",
  "Long-press a group elsewhere to favorite the whole thing.":
      "Κρατήστε πατημένη μια ομάδα αλλού για να την προσθέσετε ολόκληρη στα αγαπημένα.",
  "Nothing playing": "Δεν παίζει τίποτα",
  "Click to resume": "Κλικ για συνέχεια",
  "Filter channels in this group...": "Φιλτράρισμα καναλιών σε αυτή την ομάδα…",
  "Close filter": "Κλείσιμο φίλτρου",
  "Hidden — find it again in Settings > Playlist Manager > Hidden Channels":
      "Κρυμμένο — θα το βρείτε ξανά στις Ρυθμίσεις > Διαχείριση λιστών > Κρυμμένα κανάλια",
  "Unhidden": "Επανεμφανίστηκε",
  "No favorited movies or TV shows yet.\nHold Select on a poster to add one.":
      "Δεν υπάρχουν ακόμη αγαπημένες ταινίες ή σειρές.\nΚρατήστε το OK σε μια αφίσα για να προσθέσετε.",
  "No favorited movies yet.": "Δεν υπάρχουν ακόμη αγαπημένες ταινίες.",
  "No favorited TV shows yet.": "Δεν υπάρχουν ακόμη αγαπημένες σειρές.",
  "No favorite channels yet — press Down while watching one to add it.":
      "Δεν υπάρχουν ακόμη αγαπημένα κανάλια — πατήστε Κάτω ενώ βλέπετε ένα για να το προσθέσετε.",
  "Updating…": "Ενημέρωση…",
  "No program data": "Χωρίς δεδομένα προγράμματος",
  "No program data available": "Δεν υπάρχουν δεδομένα προγράμματος",
  "Next: {title} ({p})": "Επόμενο: {title} ({p})",
  "Focus a program to see details": "Επιλέξτε ένα πρόγραμμα για λεπτομέρειες",
  "Space": "Κενό",
  "Loading EPG…": "Φόρτωση EPG…",
  "Hey beautiful Human,": "Γεια σου, όμορφε άνθρωπε,",
  "Hey beautiful Human": "Γεια σου, όμορφε άνθρωπε",
  "Welcome to VesperTV": "Καλώς ήρθατε στο VesperTV",
  "Add your first playlist?": "Να προσθέσετε την πρώτη σας λίστα;",
  "Add a playlist to kick things off, or skip for now if you just want to browse and discover the app without content.":
      "Προσθέστε μια λίστα για να ξεκινήσετε ή παραλείψτε το αν θέλετε απλώς να εξερευνήσετε την εφαρμογή χωρίς περιεχόμενο.",
  "Add Playlist": "Προσθήκη λίστας",
  "Paste some text first.": "Επικολλήστε πρώτα κάποιο κείμενο.",
  "Couldn't find anything usable in that text.":
      "Δεν βρέθηκε κάτι χρήσιμο σε αυτό το κείμενο.",
  "Received from your phone — check the details, then press Add Playlist.":
      "Ελήφθη από το κινητό σας — ελέγξτε τα στοιχεία και πατήστε Προσθήκη λίστας.",
  "Scan the code with your phone and send the form first.":
      "Σαρώστε πρώτα τον κωδικό με το κινητό σας και στείλτε τη φόρμα.",
  "Playlist name is required.": "Απαιτείται όνομα λίστας.",
  "Server, username, and password are all required.":
      "Απαιτούνται διακομιστής, όνομα χρήστη και κωδικός.",
  "M3U playlist URL is required.": "Απαιτείται URL λίστας M3U.",
  "Playlist updated.": "Η λίστα ενημερώθηκε.",
  "Playlist added.": "Η λίστα προστέθηκε.",
  "Download content": "Λήψη περιεχομένου",
  "This provider has a large catalog. Download everything in the background, or choose which groups to include first?":
      "Αυτός ο πάροχος έχει μεγάλο κατάλογο. Λήψη όλων στο παρασκήνιο ή επιλογή των ομάδων πρώτα;",
  "Choose Groups First": "Επιλογή ομάδων πρώτα",
  "Download All": "Λήψη όλων",
  "Edit Playlist": "Επεξεργασία λίστας",
  "Playlist source": "Πηγή λίστας",
  "M3U URL": "URL M3U",
  "Xtream Codes": "Xtream Codes",
  "Smart Add": "Έξυπνη προσθήκη",
  "From phone": "Από το κινητό",
  "Playlist name": "Όνομα λίστας",
  "Name": "Όνομα",
  "e.g. My Provider, or 8kStrong": "π.χ. Ο πάροχός μου ή 8kStrong",
  "M3U Playlist URL": "URL λίστας M3U",
  "EPG (XMLTV) URL": "URL EPG (XMLTV)",
  "Paste the message your provider sent you — we'll pull out the server, username, and password.":
      "Επικολλήστε το μήνυμα που σας έστειλε ο πάροχος — θα βρούμε τον διακομιστή, το όνομα χρήστη και τον κωδικό.",
  "Paste provider message": "Επικόλληση μηνύματος παρόχου",
  "Parse": "Ανάλυση",
  "Confirm the server": "Επιβεβαίωση διακομιστή",
  "No server URL found in that text — enter it below.":
      "Δεν βρέθηκε URL διακομιστή σε αυτό το κείμενο — εισαγάγετέ το παρακάτω.",
  "Server URL (e.g. http://host:port)":
      "URL διακομιστή (π.χ. http://host:port)",
  "Username": "Όνομα χρήστη",
  "Password": "Κωδικός",
  "Custom EPG (XMLTV) URL — optional":
      "Προσαρμοσμένο URL EPG (XMLTV) — προαιρετικό",
  "Leave blank to use the panel's own xmltv.php. Set this if your provider's EPG is empty or unreliable (e.g. a third-party feed like EPGgenius) — it only fills in a channel if that feed's ids match this panel's.":
      "Αφήστε το κενό για να χρησιμοποιηθεί το xmltv.php του πάνελ. Ορίστε το αν το EPG του παρόχου είναι κενό ή αναξιόπιστο (π.χ. τρίτη πηγή όπως το EPGgenius) — συμπληρώνει ένα κανάλι μόνο αν τα αναγνωριστικά της πηγής ταιριάζουν με αυτά του πάνελ.",
  "Paste different text": "Επικόλληση άλλου κειμένου",
  "Status": "Κατάσταση",
  "Failed to add playlist: {p}": "Η προσθήκη της λίστας απέτυχε: {p}",
  "Save Changes": "Αποθήκευση αλλαγών",
  "Fill in the form on the left, then press {p} above.":
      "Συμπληρώστε τη φόρμα αριστερά και πατήστε {p} παραπάνω.",
  "Unexpected Xtream API response": "Μη αναμενόμενη απάντηση Xtream API",
  "Invalid Xtream username/password": "Λάθος όνομα χρήστη/κωδικός Xtream",
  "Xtream account is not active (status: {status})":
      "Ο λογαριασμός Xtream δεν είναι ενεργός (κατάσταση: {status})",
  "Code expired": "Ο κωδικός έληξε",
  "Add from your phone": "Προσθήκη από το κινητό σας",
  "Typing a long password with a remote is painful. Scan this code with your phone camera and fill in the form there — it appears here for you to check and add.":
      "Η πληκτρολόγηση ενός μεγάλου κωδικού με τηλεχειριστήριο είναι κουραστική. Σαρώστε αυτόν τον κωδικό με την κάμερα του κινητού σας και συμπληρώστε τη φόρμα εκεί — εμφανίζεται εδώ για έλεγχο και προσθήκη.",
  "Scan with your phone (mobile data is fine).":
      "Σαρώστε με το κινητό σας (τα δεδομένα κινητής αρκούν).",
  "Connect your phone to the same Wi-Fi as this TV, then scan.":
      "Συνδέστε το κινητό σας στο ίδιο Wi-Fi με αυτή την τηλεόραση και σαρώστε.",
  "Fill in the form and tap Send to TV.":
      "Συμπληρώστε τη φόρμα και πατήστε Αποστολή στην TV.",
  "Check the details here, then press Add Playlist.":
      "Ελέγξτε τα στοιχεία εδώ και πατήστε Προσθήκη λίστας.",
  "Waiting for your phone…": "Αναμονή για το κινητό σας…",
  "Or open on the phone:": "Ή ανοίξτε στο κινητό:",
  "Your details are encrypted on the phone; the relay only passes along scrambled data and deletes it.":
      "Τα στοιχεία σας κρυπτογραφούνται στο κινητό· ο αναμεταδότης περνά μόνο κρυπτογραφημένα δεδομένα και τα διαγράφει.",
  "New code": "Νέος κωδικός",
  "Phone on this Wi-Fi? Use the Wi-Fi code":
      "Κινητό σε αυτό το Wi-Fi; Χρησιμοποιήστε τον κωδικό Wi-Fi",
  "Phone not on this Wi-Fi? Use the other code":
      "Κινητό εκτός αυτού του Wi-Fi; Χρησιμοποιήστε τον άλλο κωδικό",
  "Add and enable a second playlist first — a link connects a channel on one playlist to its equivalent on another.":
      "Προσθέστε και ενεργοποιήστε πρώτα μια δεύτερη λίστα — μια σύνδεση συνδέει ένα κανάλι μιας λίστας με το αντίστοιχό του σε άλλη.",
  "Auto-Pair Channels": "Αυτόματη αντιστοίχιση καναλιών",
  "Unpair Channels": "Κατάργηση αντιστοίχισης καναλιών",
  "Reviewing {reviewFilter} auto-paired channel{s} — type to search all instead":
      "Έλεγχος {reviewFilter} αυτόματα αντιστοιχισμένων καναλιών — πληκτρολογήστε για αναζήτηση σε όλα",
  "Search your channels": "Αναζήτηση στα κανάλια σας",
  "Not linked": "Χωρίς σύνδεση",
  "Linked channel no longer available":
      "Το συνδεδεμένο κανάλι δεν είναι πλέον διαθέσιμο",
  "Linked to {p}: {name}": "Συνδεδεμένο με {p}: {name}",
  "Clear link": "Κατάργηση σύνδεσης",
  "Link \"{name}\"": "Σύνδεση «{name}»",
  "Search other playlists' channels": "Αναζήτηση στα κανάλια άλλων λιστών",
  "No matches.": "Καμία αντιστοιχία.",
  "No EPG feed has been loaded yet this session — run \"Update EPG Now\" first so there's a channel directory to match against.":
      "Δεν έχει φορτωθεί ακόμη πηγή EPG σε αυτή τη συνεδρία — εκτελέστε πρώτα «Ενημέρωση EPG τώρα» ώστε να υπάρχει κατάλογος καναλιών για αντιστοίχιση.",
  "No EPG feed has been loaded yet this session — run \"Update EPG Now\" above first so there's a channel directory to search.":
      "Δεν έχει φορτωθεί ακόμη πηγή EPG σε αυτή τη συνεδρία — εκτελέστε πρώτα «Ενημέρωση EPG τώρα» παραπάνω ώστε να υπάρχει κατάλογος καναλιών για αναζήτηση.",
  "Assigned: {p}": "Ανατέθηκε: {p}",
  "Matched automatically": "Αντιστοιχίστηκε αυτόματα",
  "Clear assignment": "Κατάργηση ανάθεσης",
  "Assign \"{channelName}\"": "Ανάθεση «{channelName}»",
  "Search the EPG feed's channels": "Αναζήτηση στα κανάλια της πηγής EPG",
  "No EPG feed has been loaded yet this app session — go back and run \"Update EPG Now\" first.":
      "Δεν έχει φορτωθεί ακόμη πηγή EPG σε αυτή τη συνεδρία — επιστρέψτε και εκτελέστε πρώτα «Ενημέρωση EPG τώρα».",
  "Now: {title}": "Τώρα: {title}",
  "No current program data": "Χωρίς δεδομένα τρέχοντος προγράμματος",
  "Channels are pairing, please wait…":
      "Γίνεται αντιστοίχιση καναλιών, περιμένετε…",
  "No new matches found — anything still unmatched needs a manual pick.":
      "Δεν βρέθηκαν νέες αντιστοιχίες — όσα μένουν χρειάζονται χειροκίνητη επιλογή.",
  "Paired {paired} channel{s} automatically.":
      "Αντιστοιχίστηκαν αυτόματα {paired} κανάλια.",
  "Review": "Έλεγχος",
  "Continue": "Συνέχεια",
  "Nothing was auto-paired — there's nothing to undo.":
      "Δεν έγινε καμία αυτόματη αντιστοίχιση — δεν υπάρχει κάτι να αναιρεθεί.",
  "Undo {autoPairedCount} automatic pairing{s}? Anything you've set by hand is kept.":
      "Αναίρεση {autoPairedCount} αυτόματων αντιστοιχίσεων; Ό,τι ορίσατε χειροκίνητα διατηρείται.",
  "Unpair": "Κατάργηση αντιστοίχισης",
  "Couldn't open the download link.":
      "Δεν ήταν δυνατό το άνοιγμα του συνδέσμου λήψης.",
  "Allow installing updates": "Να επιτρέπεται η εγκατάσταση ενημερώσεων",
  "Android needs one-time permission for VesperTV to install an update it downloaded. The next screen is Android's own settings — turn the toggle on, then come back here and press Install again.":
      "Το Android χρειάζεται εφάπαξ άδεια ώστε το VesperTV να εγκαταστήσει μια ενημέρωση που κατέβασε. Η επόμενη οθόνη είναι οι ρυθμίσεις του Android — ενεργοποιήστε τον διακόπτη, επιστρέψτε εδώ και πατήστε ξανά Εγκατάσταση.",
  "Check for Updates": "Έλεγχος για ενημερώσεις",
  "Current version: —": "Τρέχουσα έκδοση: —",
  "Current version: {currentVersion}": "Τρέχουσα έκδοση: {currentVersion}",
  "Checking...": "Έλεγχος…",
  "You're on the latest version.": "Έχετε την τελευταία έκδοση.",
  "Check Again": "Έλεγχος ξανά",
  "Version {version} is available": "Η έκδοση {version} είναι διαθέσιμη",
  "Open Download Page": "Άνοιγμα σελίδας λήψης",
  "Opens in your browser — unzip the download and run VesperTV.exe to update, replacing the old folder.":
      "Ανοίγει στον browser — αποσυμπιέστε τη λήψη και εκτελέστε το VesperTV.exe για ενημέρωση, αντικαθιστώντας τον παλιό φάκελο.",
  "Download & Install": "Λήψη και εγκατάσταση",
  "Downloading update... {p}%": "Λήψη ενημέρωσης… {p}%",
  "Download complete.": "Η λήψη ολοκληρώθηκε.",
  "Install": "Εγκατάσταση",
  "Android will ask you to confirm the install — that's normal, not every app can skip it.":
      "Το Android θα ζητήσει επιβεβαίωση της εγκατάστασης — είναι φυσιολογικό, δεν μπορούν όλες οι εφαρμογές να το παραλείψουν.",
  "Something went wrong: {p}": "Κάτι πήγε στραβά: {p}",
  "unknown error": "άγνωστο σφάλμα",
  "Try Again": "Ξανά",
  "GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minute.":
      "Το GitHub περιορίζει προσωρινά τους ελέγχους ενημερώσεων από αυτό το δίκτυο — δοκιμάστε ξανά σε περίπου {n} λεπτό.",
  "GitHub is temporarily rate-limiting update checks from this network — try again in about {n} minutes.":
      "Το GitHub περιορίζει προσωρινά τους ελέγχους ενημερώσεων από αυτό το δίκτυο — δοκιμάστε ξανά σε περίπου {n} λεπτά.",
  "GitHub is temporarily rate-limiting update checks from this network — try again shortly.":
      "Το GitHub περιορίζει προσωρινά τους ελέγχους ενημερώσεων από αυτό το δίκτυο — δοκιμάστε ξανά σε λίγο.",
  "No EPG URL set yet — add a playlist first.":
      "Δεν έχει οριστεί ακόμη URL EPG — προσθέστε πρώτα μια λίστα.",
  "Cache cleared.": "Η προσωρινή μνήμη καθαρίστηκε.",
  "EPG": "EPG",
  "General": "Γενικά",
  "EPG Matching": "Αντιστοίχιση EPG",
  "Channel Pairing": "Αντιστοίχιση καναλιών",
  "Auto-refresh interval": "Διάστημα αυτόματης ανανέωσης",
  "{p} hours": "{p} ώρες",
  "EPG never updated": "Το EPG δεν έχει ενημερωθεί ποτέ",
  "EPG last updated: {p}": "Τελευταία ενημέρωση EPG: {p}",
  "Update EPG Now": "Ενημέρωση EPG τώρα",
  "Clear Cache": "Καθαρισμός προσωρινής μνήμης",
  "Clears the cached EPG and catalog data — playlist source, favorites, and group visibility are kept.":
      "Καθαρίζει τα αποθηκευμένα δεδομένα EPG και καταλόγου — η πηγή της λίστας, τα αγαπημένα και η ορατότητα ομάδων διατηρούνται.",
  "Fixes a channel with no program data by manually assigning it to an entry in the loaded EPG feed — useful when a provider's own id doesn't match a third-party source.":
      "Διορθώνει ένα κανάλι χωρίς δεδομένα προγράμματος αναθέτοντάς το χειροκίνητα σε μια εγγραφή της φορτωμένης πηγής EPG — χρήσιμο όταν το αναγνωριστικό του παρόχου δεν ταιριάζει με τρίτη πηγή.",
  "Links a channel on one playlist to its equivalent on another. If a live channel fails to load, or you switch to it yourself from the player, playback can fall back to the paired channel on the other playlist instead.":
      "Συνδέει ένα κανάλι μιας λίστας με το αντίστοιχό του σε άλλη. Αν ένα ζωντανό κανάλι δεν φορτώσει ή αλλάξετε σε αυτό από τον player, η αναπαραγωγή μπορεί να περάσει στο αντιστοιχισμένο κανάλι της άλλης λίστας.",
  "Clear search & channel history?":
      "Καθαρισμός ιστορικού αναζήτησης και καναλιών;",
  "Removes your recent searches and the History list of live channels.":
      "Αφαιρεί τις πρόσφατες αναζητήσεις και τη λίστα Ιστορικού των ζωντανών καναλιών.",
  "Search and channel history cleared.":
      "Το ιστορικό αναζήτησης και καναλιών καθαρίστηκε.",
  "Clear Movies & TV Shows history?":
      "Καθαρισμός ιστορικού Ταινιών και Σειρών;",
  "Removes Continue Watching and the saved progress of every movie and episode.":
      "Αφαιρεί τη Συνέχεια παρακολούθησης και την αποθηκευμένη πρόοδο κάθε ταινίας και επεισοδίου.",
  "Movies & TV Shows history cleared.":
      "Το ιστορικό Ταινιών και Σειρών καθαρίστηκε.",
  "Language": "Γλώσσα",
  "Follows the device language": "Ακολουθεί τη γλώσσα της συσκευής",
  "Automatic": "Αυτόματα",
  "Startup": "Εκκίνηση",
  "Resume last channel in full screen":
      "Συνέχεια τελευταίου καναλιού σε πλήρη οθόνη",
  "Opens the last live channel full screen after the splash.":
      "Ανοίγει το τελευταίο ζωντανό κανάλι σε πλήρη οθόνη μετά την οθόνη εκκίνησης.",
  "Resume last channel with the guide open":
      "Συνέχεια τελευταίου καναλιού με ανοιχτό τον οδηγό",
  "Plays the last live channel in the small preview, with the channel list.":
      "Παίζει το τελευταίο ζωντανό κανάλι στη μικρή προεπισκόπηση, με τη λίστα καναλιών.",
  "Both off: nothing plays at startup (a \"Hold > to resume\" reminder instead).":
      "Και τα δύο ανενεργά: τίποτα δεν παίζει στην εκκίνηση (αντί γι' αυτό, υπενθύμιση «Κρατήστε > για συνέχεια»).",
  "Tabs": "Καρτέλες",
  "Hide Movies and TV Shows": "Απόκρυψη Ταινιών και Σειρών",
  "Removes both tabs and their search results, e.g. if you watch movies and shows elsewhere.":
      "Αφαιρεί και τις δύο καρτέλες και τα αποτελέσματα αναζήτησής τους, π.χ. αν βλέπετε ταινίες και σειρές αλλού.",
  "Favorite channels are in the TV tab, under Favourites.":
      "Τα αγαπημένα κανάλια βρίσκονται στην καρτέλα TV, στα Αγαπημένα.",
  "Show the Multiview tip": "Εμφάνιση της συμβουλής Multiview",
  "The connections reminder shown when opening Multiview.":
      "Η υπενθύμιση για τις συνδέσεις που εμφανίζεται όταν ανοίγει το Multiview.",
  "Resume reminder": "Υπενθύμιση συνέχειας",
  "Show the \"Hold > to resume\" reminder":
      "Εμφάνιση της υπενθύμισης «Κρατήστε > για συνέχεια»",
  "The pill at the bottom while a channel plays in the background. Off: hidden.":
      "Η ένδειξη στο κάτω μέρος όσο ένα κανάλι παίζει στο παρασκήνιο. Ανενεργό: κρυφή.",
  "The pill at the bottom while a channel plays in the background. Off: hidden — holding Right still resumes.":
      "Η ένδειξη στο κάτω μέρος όσο ένα κανάλι παίζει στο παρασκήνιο. Ανενεργό: κρυφή — κρατώντας το Δεξιά γίνεται ακόμη συνέχεια.",
  "Clear search & channel history":
      "Καθαρισμός ιστορικού αναζήτησης και καναλιών",
  "Recent searches and the live channel History":
      "Πρόσφατες αναζητήσεις και Ιστορικό ζωντανών καναλιών",
  "Clear Movies & TV Shows history": "Καθαρισμός ιστορικού Ταινιών και Σειρών",
  "Continue Watching and saved progress":
      "Συνέχεια παρακολούθησης και αποθηκευμένη πρόοδος",
  "Leave group selection?": "Έξοδος από την επιλογή ομάδων;",
  "Your show/hide choices are saved, and anything still visible will start downloading — same as pressing Done.":
      "Οι επιλογές εμφάνισης/απόκρυψης αποθηκεύονται και ό,τι μένει ορατό ξεκινά να κατεβαίνει — όπως με το Τέλος.",
  "Leave": "Έξοδος",
  "Save playlist?": "Αποθήκευση λίστας;",
  "Your playlist will be saved with the selected groups. You can always add or remove groups later in Settings > Group Management.":
      "Η λίστα θα αποθηκευτεί με τις επιλεγμένες ομάδες. Μπορείτε πάντα να προσθέσετε ή να αφαιρέσετε ομάδες αργότερα στις Ρυθμίσεις > Διαχείριση ομάδων.",
  "Confirm": "Επιβεβαίωση",
  "Group Management": "Διαχείριση ομάδων",
  "Done": "Τέλος",
  "If you are done selecting your groups, press Confirm below.\n\nIf you are not done yet, press Left to go back to your categories.":
      "Αν τελειώσατε την επιλογή ομάδων, πατήστε Επιβεβαίωση παρακάτω.\n\nΑν όχι ακόμη, πατήστε Αριστερά για να επιστρέψετε στις κατηγορίες.",
  "No categories yet — load a playlist first.":
      "Δεν υπάρχουν ακόμη κατηγορίες — φορτώστε πρώτα μια λίστα.",
  'Search groups (starts with)': 'Αναζήτηση ομάδων (αρχίζει με)',
  '{shown} of {total} groups': '{shown} από {total} ομάδες',
  'Show results': 'Εμφάνιση αποτελεσμάτων',
  'Hide results': 'Απόκρυψη αποτελεσμάτων',
  'No groups start with "{query}".': 'Καμία ομάδα δεν αρχίζει με «{query}».',
  "Show All": "Εμφάνιση όλων",
  "Hide All": "Απόκρυψη όλων",
  "Hidden channels": "Κρυμμένα κανάλια",
  "No channels are individually hidden. Hide one from its row in the Live TV list.":
      "Κανένα κανάλι δεν είναι κρυμμένο μεμονωμένα. Κρύψτε ένα από τη γραμμή του στη λίστα Ζωντανής TV.",
  "Unhide": "Επανεμφάνιση",
  "Show group": "Εμφάνιση ομάδας",
  "Hide group": "Απόκρυψη ομάδας",
  "Playlist Manager": "Διαχείριση λιστών",
  "Playlist Priority": "Προτεραιότητα λιστών",
  "Which playlist's groups show first, per tab":
      "Ποιας λίστας οι ομάδες εμφανίζονται πρώτες, ανά καρτέλα",
  "No playlists yet — tap \"Add Playlist\" above to get started.":
      "Δεν υπάρχουν ακόμη λίστες — πατήστε «Προσθήκη λίστας» παραπάνω για να ξεκινήσετε.",
  "Delete playlist?": "Διαγραφή λίστας;",
  "This removes \"{name}\"'s login and cached catalog from this device. Its favorited channels/movies stay in your shared Favorites list, but will no longer play unless you add this playlist back.":
      "Αφαιρεί τη σύνδεση και τον αποθηκευμένο κατάλογο της «{name}» από αυτή τη συσκευή. Τα αγαπημένα κανάλια/ταινίες της μένουν στα κοινά Αγαπημένα, αλλά δεν θα παίζουν μέχρι να προσθέσετε ξανά τη λίστα.",
  "Delete": "Διαγραφή",
  "Add backup server": "Προσθήκη εφεδρικού διακομιστή",
  "The full address, exactly like the main one — for example http://backup.example.com:8080":
      "Η πλήρης διεύθυνση, όπως η κύρια — για παράδειγμα http://backup.example.com:8080",
  "Server address": "Διεύθυνση διακομιστή",
  "Add": "Προσθήκη",
  "Edit login": "Επεξεργασία σύνδεσης",
  "Delete playlist": "Διαγραφή λίστας",
  "This Playlist": "Αυτή η λίστα",
  "Playlist enabled": "Η λίστα είναι ενεργή",
  "Frees up this account's stream slot for another device — stops playback here immediately, keeps everything else intact.":
      "Ελευθερώνει τη θέση ροής αυτού του λογαριασμού για άλλη συσκευή — σταματά αμέσως την αναπαραγωγή εδώ, όλα τα άλλα μένουν ανέπαφα.",
  "Login Details": "Στοιχεία σύνδεσης",
  "Server": "Διακομιστής",
  "Expires": "Λήγει",
  "Max connections": "Μέγιστες συνδέσεις",
  "Backup Servers": "Εφεδρικοί διακομιστές",
  "None yet. If your provider gave you more than one server address for this same account, add them here and this playlist will try them in order whenever the main one can't be reached.":
      "Κανένας ακόμη. Αν ο πάροχος σας έδωσε περισσότερες από μία διευθύνσεις διακομιστή για τον ίδιο λογαριασμό, προσθέστε τις εδώ και η λίστα θα τις δοκιμάζει με τη σειρά όταν ο κύριος δεν απαντά.",
  "Same username and password as above — only the address differs. Tried in order, a few seconds apart, and whichever answers is used first next time.":
      "Ίδιο όνομα χρήστη και κωδικός με παραπάνω — αλλάζει μόνο η διεύθυνση. Δοκιμάζονται με τη σειρά, με λίγα δευτερόλεπτα διαφορά, και όποιος απαντήσει χρησιμοποιείται πρώτος την επόμενη φορά.",
  "Content Overview": "Επισκόπηση περιεχομένου",
  "Not loaded yet.": "Δεν έχει φορτωθεί ακόμη.",
  "{p} live channels · {p2} movie categories · {p3} TV show categories":
      "{p} ζωντανά κανάλια · {p2} κατηγορίες ταινιών · {p3} κατηγορίες σειρών",
  "{p} live · {p2} movies · {p3} TV shows":
      "{p} ζωντανά · {p2} ταινίες · {p3} σειρές",
  "Last updated: {p}": "Τελευταία ενημέρωση: {p}",
  "Added: {p}": "Προστέθηκε: {p}",
  "Hidden Channels": "Κρυμμένα κανάλια",
  "Hide a group here and it's excluded from the background download too, not just the browse tabs.":
      "Μια ομάδα που κρύβετε εδώ εξαιρείται και από τη λήψη στο παρασκήνιο, όχι μόνο από τις καρτέλες περιήγησης.",
  "Full Catalog Sync": "Πλήρης συγχρονισμός καταλόγου",
  "Update content every": "Ενημέρωση περιεχομένου κάθε",
  "1 day": "1 ημέρα",
  "{d} days": "{d} ημέρες",
  "A stale sync prompts \"Update content now?\" on launch instead of running automatically.":
      "Ένας παλιός συγχρονισμός εμφανίζει «Ενημέρωση περιεχομένου τώρα;» στην εκκίνηση αντί να γίνεται αυτόματα.",
  "in use": "σε χρήση",
  "Remove {server}": "Αφαίρεση {server}",
  "Which playlist's groups show first — set independently for each tab below.":
      "Ποιας λίστας οι ομάδες εμφανίζονται πρώτες — ορίζεται χωριστά για κάθε καρτέλα παρακάτω.",
  "Add another enabled playlist to set a priority between them.":
      "Προσθέστε άλλη ενεργή λίστα για να ορίσετε προτεραιότητα μεταξύ τους.",
  "Live TV order": "Σειρά Ζωντανής TV",
  "Movies order": "Σειρά Ταινιών",
  "TV Shows order": "Σειρά Σειρών",
  "Move up": "Μετακίνηση πάνω",
  "Move down": "Μετακίνηση κάτω",
  "Playlist added": "Η λίστα προστέθηκε",
  "This playlist is disabled on this device — enable it in Settings > Playlist Manager to watch.":
      "Αυτή η λίστα είναι ανενεργή σε αυτή τη συσκευή — ενεργοποιήστε την στις Ρυθμίσεις > Διαχείριση λιστών για να τη δείτε.",
  "Profiles": "Προφίλ",
  "Add Profile": "Προσθήκη προφίλ",
  "Rename profile": "Μετονομασία προφίλ",
  "Delete \"{name}\"?": "Διαγραφή του «{name}»;",
  "Their favorites, hidden groups, and watch history are deleted too. This can't be undone.":
      "Διαγράφονται επίσης τα αγαπημένα, οι κρυμμένες ομάδες και το ιστορικό του. Δεν αναιρείται.",
  "Switch to another profile before deleting this one":
      "Αλλάξτε σε άλλο προφίλ πριν διαγράψετε αυτό",
  "Delete profile": "Διαγραφή προφίλ",
  "This is the active profile": "Αυτό είναι το ενεργό προφίλ",
  "Switch to this profile": "Αλλαγή σε αυτό το προφίλ",
  "Rename": "Μετονομασία",
  "What this profile can see": "Τι μπορεί να βλέπει αυτό το προφίλ",
  "Groups — {name}": "Ομάδες — {name}",
  "Hidden channels — {name}": "Κρυμμένα κανάλια — {name}",
  "For a child — hides every group, including adult content, by default. A parent unhides specific categories per playlist afterward in Group Management. A PIN is required to switch away from this profile or to open Settings while it's active.":
      "Για παιδί — κρύβει από προεπιλογή κάθε ομάδα, μαζί με το περιεχόμενο για ενήλικες. Ένας γονιός επανεμφανίζει μετά συγκεκριμένες κατηγορίες ανά λίστα στη Διαχείριση ομάδων. Απαιτείται PIN για αλλαγή από αυτό το προφίλ ή για άνοιγμα των Ρυθμίσεων όσο είναι ενεργό.",
  "Create": "Δημιουργία",
  "Incorrect PIN": "Λάθος PIN",
  "PINs didn't match — try again": "Τα PIN δεν ταιριάζουν — δοκιμάστε ξανά",
  "Enter PIN": "Εισαγάγετε PIN",
  "Confirm PIN": "Επιβεβαίωση PIN",
  "Set a PIN": "Ορισμός PIN",
  "Too many attempts — try again in {p}s":
      "Πάρα πολλές προσπάθειες — δοκιμάστε ξανά σε {p} δ",
  "M3U URL or Xtream Codes login": "URL M3U ή σύνδεση Xtream Codes",
  "Every playlist: login, groups, enable/disable":
      "Κάθε λίστα: σύνδεση, ομάδες, ενεργοποίηση/απενεργοποίηση",
  "Separate favorites, history & hidden groups per viewer":
      "Ξεχωριστά αγαπημένα, ιστορικό και κρυμμένες ομάδες ανά θεατή",
  "Language and history": "Γλώσσα και ιστορικό",
  "Language, startup, Multiview and history":
      "Γλώσσα, εκκίνηση, Multiview και ιστορικό",
  "Theme": "Θέμα",
  "Clock, accent color, layout": "Ρολόι, χρώμα έμφασης, διάταξη",
  "Auto-refresh, channel matching & pairing, clear cache":
      "Αυτόματη ανανέωση, αντιστοίχιση και ζεύξη καναλιών, καθαρισμός προσωρινής μνήμης",
  "TMDB (Release Dates)": "TMDB (ημερομηνίες κυκλοφορίας)",
  "Optional key for sorting by real release date":
      "Προαιρετικό κλειδί για ταξινόμηση κατά πραγματική ημερομηνία κυκλοφορίας",
  "Download and install the latest release":
      "Λήψη και εγκατάσταση της τελευταίας έκδοσης",
  "Version —": "Έκδοση —",
  "Version {version}": "Έκδοση {version}",
  "Report any bugs or glitches to noxqcx@gmail.com":
      "Αναφέρετε σφάλματα ή προβλήματα στο noxqcx@gmail.com",
  "Show clock": "Εμφάνιση ρολογιού",
  "Displays the current time in the top bar":
      "Δείχνει την τρέχουσα ώρα στην πάνω μπάρα",
  "Theme color": "Χρώμα θέματος",
  "Auto picks phone vs TV layout by screen size — force one if your box isn't detected correctly.":
      "Το Αυτόματο επιλέγει διάταξη κινητού ή TV ανάλογα με την οθόνη — επιβάλετε μία αν η συσκευή σας δεν αναγνωρίζεται σωστά.",
  "Live TV guide": "Οδηγός ζωντανής TV",
  "Timeline shows every channel at once, on a scrollable schedule grid, instead of one channel's now/next at a time.":
      "Το Χρονολόγιο δείχνει όλα τα κανάλια μαζί, σε ένα πλέγμα προγράμματος με κύλιση, αντί για το τώρα/επόμενο ενός καναλιού κάθε φορά.",
  "Full-screen video behind the guide":
      "Βίντεο πλήρους οθόνης πίσω από τον οδηγό",
  "The live channel fills the screen behind a see-through guide showing 3 rows":
      "Το ζωντανό κανάλι γεμίζει την οθόνη πίσω από έναν διάφανο οδηγό με 3 σειρές",
  "Auto": "Αυτόματα",
  "Phone": "Κινητό",
  "Timeline": "Χρονολόγιο",
  "Platinum": "Πλατινένιο",
  "Rosé": "Ροζέ",
  "Neon Purple": "Νέον μωβ",
  "Neon Green": "Νέον πράσινο",
  "Aqua": "Ακουαμαρίνα",
  "Red": "Κόκκινο",
  "Blue": "Μπλε",
  "Dark / Gold": "Σκούρο / Χρυσό",
  "Cleared — TMDB sorting is now off":
      "Καθαρίστηκε — η ταξινόμηση TMDB είναι πλέον ανενεργή",
  "Saved — key verified with TMDB ✓":
      "Αποθηκεύτηκε — το κλειδί επαληθεύτηκε με το TMDB ✓",
  "Saved, but TMDB rejected this key — double-check it's correct":
      "Αποθηκεύτηκε, αλλά το TMDB απέρριψε το κλειδί — ελέγξτε ότι είναι σωστό",
  "What's New refreshed from TMDB": "Το Τι νέο υπάρχει ανανεώθηκε από το TMDB",
  "TMDB (The Movie Database) is a free, independent movie and TV database — not your IPTV provider. Adding your own free TMDB key lets VesperTV look up a title's actual real-world release date, which powers two things: a \"TMDB\" sort option on any group's \"Expand catalog\" screen, and a more accurate \"What's New\" row (ordered by real release date instead of just when your provider added the title).":
      "Το TMDB (The Movie Database) είναι μια δωρεάν, ανεξάρτητη βάση δεδομένων ταινιών και σειρών — όχι ο πάροχος IPTV σας. Με το δικό σας δωρεάν κλειδί TMDB, το VesperTV βρίσκει την πραγματική ημερομηνία κυκλοφορίας ενός τίτλου, που χρησιμοποιείται σε δύο σημεία: μια επιλογή ταξινόμησης «TMDB» στην οθόνη «Επέκταση καταλόγου» κάθε ομάδας και μια πιο ακριβή σειρά «Τι νέο υπάρχει» (κατά πραγματική ημερομηνία κυκλοφορίας αντί για το πότε πρόσθεσε τον τίτλο ο πάροχος).",
  "This is completely optional and free — VesperTV works 100% without it. Without a key, sorting just falls back to whenever your provider added or updated each title, which is still available and works fine on its own.":
      "Είναι εντελώς προαιρετικό και δωρεάν — το VesperTV λειτουργεί 100% και χωρίς αυτό. Χωρίς κλειδί, η ταξινόμηση βασίζεται στο πότε ο πάροχος πρόσθεσε ή ενημέρωσε κάθε τίτλο, που είναι πάντα διαθέσιμο και λειτουργεί μια χαρά.",
  "To get one: create a free account at themoviedb.org, then generate an API key under Settings > API (choose \"Personal use\" when asked) and paste it below. VesperTV never collects or shares it — it's stored only on this device.":
      "Για να πάρετε ένα: δημιουργήστε δωρεάν λογαριασμό στο themoviedb.org, δημιουργήστε ένα κλειδί API στις Settings > API (επιλέξτε «Personal use» όταν ερωτηθείτε) και επικολλήστε το παρακάτω. Το VesperTV δεν το συλλέγει ούτε το κοινοποιεί — αποθηκεύεται μόνο σε αυτή τη συσκευή.",
  "TMDB API Key": "Κλειδί API TMDB",
  "What's New only re-checks TMDB about once a week on its own. Use this to force it right now instead of waiting — useful right after saving a key for the first time.":
      "Το Τι νέο υπάρχει ελέγχει ξανά το TMDB μόνο του περίπου μία φορά την εβδομάδα. Χρησιμοποιήστε αυτό για να το κάνετε τώρα — χρήσιμο αμέσως μετά την πρώτη αποθήκευση κλειδιού.",
  "Refresh What's New Now": "Ανανέωση του Τι νέο υπάρχει τώρα",
  "This product uses the TMDB API but is not endorsed or certified by TMDB.":
      "Αυτό το προϊόν χρησιμοποιεί το TMDB API αλλά δεν έχει εγκριθεί ή πιστοποιηθεί από το TMDB.",
  "No Title": "Χωρίς τίτλο",
  "Reconnecting...": "Επανασύνδεση…",
  "Trying to reconnect on backup servers ({p}/{candidates})...":
      "Προσπάθεια επανασύνδεσης σε εφεδρικούς διακομιστές ({p}/{candidates})…",
  "Finding live channels... ({p} found)":
      "Αναζήτηση ζωντανών καναλιών… (βρέθηκαν {p})",
  "Finding movies... ({p} found)": "Αναζήτηση ταινιών… (βρέθηκαν {p})",
  "Finding TV shows... ({p} found)": "Αναζήτηση σειρών… (βρέθηκαν {p})",
  "Connecting to {label} ({p}/{candidates})...":
      "Σύνδεση με {label} ({p}/{candidates})…",
  "Connected to {label}": "Συνδέθηκε με {label}",
  "Connecting to {label} ({p}/{candidates})... failed":
      "Σύνδεση με {label} ({p}/{candidates})… απέτυχε",
  "Finding live channels...": "Αναζήτηση ζωντανών καναλιών…",
  "Finding live channels... ({loadedLive} found)":
      "Αναζήτηση ζωντανών καναλιών… (βρέθηκαν {loadedLive})",
  "Finding movie categories...": "Αναζήτηση κατηγοριών ταινιών…",
  "Finding movies... ({vodCategories} categories found)":
      "Αναζήτηση ταινιών… (βρέθηκαν {vodCategories} κατηγορίες)",
  "Finding TV show categories...": "Αναζήτηση κατηγοριών σειρών…",
  "Finding TV shows... ({seriesCategories} categories found)":
      "Αναζήτηση σειρών… (βρέθηκαν {seriesCategories} κατηγορίες)",
  "Loading full catalog in the background — {p}":
      "Φόρτωση πλήρους καταλόγου στο παρασκήνιο — {p}",
  "Ready": "Έτοιμο",
  "{done}/{total} categories": "{done}/{total} κατηγορίες",
  "Failed to load EPG (HTTP {code})": "Η φόρτωση του EPG απέτυχε (HTTP {code})",
  "Failed to load playlist from {host} (HTTP {code})":
      "Η φόρτωση της λίστας από {host} απέτυχε (HTTP {code})",
  "Xtream request to {server} failed: {action} (HTTP {code})":
      "Το αίτημα Xtream προς {server} απέτυχε: {action} (HTTP {code})",
  "Main": "Κύριο",
  "{h}h ": "{h}ω",
  "Unpin": "Ξεκαρφίτσωμα",
  "Pin as favorite": "Καρφίτσωμα ως αγαπημένο",
  "Next: {p}": "Επόμενο: {p}",
  "NOW: {title} ({p}-{p2})": "ΤΩΡΑ: {title} ({p}-{p2})",
  "NEXT: {title} ({p})": "ΕΠΟΜΕΝΟ: {title} ({p})",
  "Hold ": "Κρατήστε",
  " to resume": " για συνέχεια",
  "Expand sidebar": "Ανάπτυξη πλευρικής στήλης",
  "Collapse sidebar": "Σύμπτυξη πλευρικής στήλης",
  "Pinned channels": "Καρφιτσωμένα κανάλια",
  "League manager": "Διαχείριση πρωταθλημάτων",
  "Your leagues": "Τα πρωταθλήματά σας",
  "League bank": "Τράπεζα πρωταθλημάτων",
  "Every league is added.": "Όλα τα πρωταθλήματα έχουν προστεθεί.",
  "Added · hold to send back": "Προστέθηκε · κρατήστε για επιστροφή",
  "{name} is back in the league bank":
      "Το {name} επέστρεψε στην τράπεζα πρωταθλημάτων",
  "England": "Αγγλία",
  "Spain": "Ισπανία",
  "Germany": "Γερμανία",
  "Italy": "Ιταλία",
  "France": "Γαλλία",
  "Europe": "Ευρώπη",
  "Cups": "Κύπελλα",
  "Americas": "Αμερική",
  "World": "Κόσμος",
  "Women": "Γυναίκες",
  "Basketball": "Μπάσκετ",
  "Hockey": "Χόκεϊ",
  "Baseball": "Μπέιζμπολ",
  "Other": "Άλλο",
  "Golf": "Γκολφ",
  "Tennis": "Τένις",
  'Rugby': "Ράγκμπι",
  'Cricket': "Κρίκετ",
  'Darts': "Βελάκια",
  "Fighting": "Μάχες",
  "Motorsport": "Μηχανοκίνητα",
  "Always for {name}": "Πάντα για {name}",
  "Best for a channel that carries the whole series":
      "Καλύτερο για κανάλι που μεταδίδει όλη τη διοργάνωση",
  "Next game: {date}": "Επόμενο παιχνίδι: {date}",
  "No upcoming games listed yet for this league.":
      "Δεν υπάρχουν ακόμη επερχόμενα παιχνίδια για αυτό το πρωτάθλημα.",
  "Transfer to another device": "Μεταφορά σε άλλη συσκευή",
  "Copy all of your data to another device":
      "Αντιγραφή όλων των δεδομένων σας σε άλλη συσκευή",
  "Copies your playlists, favorites, hidden groups, profiles, watch progress, {tab} (leagues, favourite league, My Teams) and settings to another device. On the same Wi-Fi it goes straight across; anywhere else it goes through an encrypted upload only the code can open. Channels, movies and the guide download again on the new device.":
      "Αντιγράφει τις λίστες, τα αγαπημένα, τις κρυμμένες ομάδες, τα προφίλ, την πρόοδο παρακολούθησης, το {tab} (πρωταθλήματα, αγαπημένο πρωτάθλημα, Οι ομάδες μου) και τις ρυθμίσεις σε άλλη συσκευή. Στο ίδιο Wi-Fi περνούν απευθείας· αλλού μέσω κρυπτογραφημένης μεταφόρτωσης που ανοίγει μόνο με τον κωδικό. Τα κανάλια, οι ταινίες και ο οδηγός κατεβαίνουν ξανά στη νέα συσκευή.",
  "This setup is too big to upload. Use the same-Wi-Fi transfer instead.":
      "Αυτή η ρύθμιση είναι πολύ μεγάλη για μεταφόρτωση. Χρησιμοποιήστε τη μεταφορά στο ίδιο Wi-Fi.",
  "Couldn't reach the VesperTV transfer server. Check this device's internet connection and try again.":
      "Δεν ήταν δυνατή η σύνδεση με τον διακομιστή μεταφοράς του VesperTV. Ελέγξτε τη σύνδεση της συσκευής στο διαδίκτυο και δοκιμάστε ξανά.",
  "{n} hour": "{n} ώρα",
  "{n} hours": "{n} ώρες",
  "{n} day": "{n} ημέρα",
  "{n} days": "{n} ημέρες",
  "Your setup is encrypted on this device and uploaded. Any device that enters the code can copy it until it expires — even with this device turned off. How long should it stay available?":
      "Η ρύθμισή σας κρυπτογραφείται σε αυτή τη συσκευή και μεταφορτώνεται. Κάθε συσκευή που εισάγει τον κωδικό μπορεί να την αντιγράψει μέχρι να λήξει — ακόμη κι αν αυτή η συσκευή είναι κλειστή. Για πόσο να μείνει διαθέσιμη;",
  "Encrypting and uploading…": "Κρυπτογράφηση και μεταφόρτωση…",
  "Works on any network until {time}":
      "Λειτουργεί σε οποιοδήποτε δίκτυο έως {time}",
  "Anyone with this code can copy your setup, playlist logins included. Changes made after this upload aren't in it — upload again to update it.":
      "Όποιος έχει αυτόν τον κωδικό μπορεί να αντιγράψει τη ρύθμισή σας, μαζί με τις συνδέσεις των λιστών. Αλλαγές μετά τη μεταφόρτωση δεν περιλαμβάνονται — μεταφορτώστε ξανά για ενημέρωση.",
  "Upload again": "Μεταφόρτωση ξανά",
  "Delete now": "Διαγραφή τώρα",
  "Nothing was found for that code. Check it — the upload may also have expired or been deleted.":
      "Δεν βρέθηκε τίποτα για αυτόν τον κωδικό. Ελέγξτε τον — η μεταφόρτωση μπορεί επίσης να έχει λήξει ή διαγραφεί.",
  "9 digits on the same Wi-Fi, 16 digits over the internet":
      "9 ψηφία στο ίδιο Wi-Fi, 16 ψηφία μέσω διαδικτύου",
  "24-hour clock": "24ωρο ρολόι",
  "Times show as 21:30": "Οι ώρες εμφανίζονται ως 21:30",
  "Times show as 9:30 PM": "Οι ώρες εμφανίζονται ως 9:30 μ.μ.",
  "Welcome back, legend": "Καλώς ήρθες ξανά, θρύλε",
  "No favourites yet. Hold Select on a poster or a group to add one.":
      "Δεν υπάρχουν ακόμη αγαπημένα. Κρατήστε το OK σε μια αφίσα ή ομάδα για να προσθέσετε.",
  "Rotate": "Περιστροφή",
  "You have great taste": "Έχεις εξαιρετικό γούστο",
  "Looking sharp today": "Είσαι εντυπωσιακός σήμερα",
  "You make this place better": "Κάνεις αυτό το μέρος καλύτερο",
  "Hey superstar": "Γεια σου, σούπερ σταρ",
  "You deserve this break": "Σου αξίζει αυτό το διάλειμμα",
  "You're doing amazing": "Τα πας καταπληκτικά",
  "Hello, wonderful you": "Γεια σου, υπέροχε άνθρωπε",
  "Smart choice, as always": "Έξυπνη επιλογή, όπως πάντα",
  "You light up the room": "Φωτίζεις τον χώρο",
  "Keep shining, you've got this": "Συνέχισε να λάμπεις, τα καταφέρνεις",
  "You earned some fun today": "Σου αξίζει λίγη διασκέδαση σήμερα",
  "The world is better with you in it": "Ο κόσμος είναι καλύτερος μαζί σου",
  "Hey champ, welcome in": "Γεια σου, πρωταθλητή, καλώς ήρθες",
  "Send from this device": "Αποστολή από αυτή τη συσκευή",
  "Shows a code to enter on the other device":
      "Εμφανίζει έναν κωδικό για εισαγωγή στην άλλη συσκευή",
  "Both devices on the same Wi-Fi?": "Και οι δύο συσκευές στο ίδιο Wi-Fi;",
  "Send directly, without uploading": "Απευθείας αποστολή, χωρίς μεταφόρτωση",
  "Receive on this device": "Λήψη σε αυτή τη συσκευή",
  "Replaces this device's setup with the other one's":
      "Αντικαθιστά τη ρύθμιση αυτής της συσκευής με εκείνη της άλλης",
  "This device isn't on a Wi-Fi or wired home network.":
      "Αυτή η συσκευή δεν είναι σε Wi-Fi ή ενσύρματο οικιακό δίκτυο.",
  "Sent! Finish on the other device.":
      "Στάλθηκε! Ολοκληρώστε στην άλλη συσκευή.",
  "This code has expired. Go back and start again.":
      "Αυτός ο κωδικός έληξε. Επιστρέψτε και ξεκινήστε ξανά.",
  "On the other device, open Settings > Transfer to another device > Receive, and enter:":
      "Στην άλλη συσκευή, ανοίξτε Ρυθμίσεις > Μεταφορά σε άλλη συσκευή > Λήψη και εισαγάγετε:",
  "This device: {address} · the code works once, for 10 minutes":
      "Αυτή η συσκευή: {address} · ο κωδικός λειτουργεί μία φορά, για 10 λεπτά",
  "Couldn't find the other device. Check the code, and that both devices are on the same Wi-Fi with the code still showing.":
      "Δεν βρέθηκε η άλλη συσκευή. Ελέγξτε τον κωδικό και ότι και οι δύο συσκευές είναι στο ίδιο Wi-Fi με τον κωδικό ακόμη στην οθόνη.",
  "That code isn't right. Check it on the other device.":
      "Ο κωδικός δεν είναι σωστός. Ελέγξτε τον στην άλλη συσκευή.",
  "That code has expired or was already used. Start again on the other device.":
      "Ο κωδικός έληξε ή χρησιμοποιήθηκε ήδη. Ξεκινήστε ξανά στην άλλη συσκευή.",
  "The transfer didn't go through. Try again.":
      "Η μεταφορά δεν ολοκληρώθηκε. Δοκιμάστε ξανά.",
  "Transfer complete": "Η μεταφορά ολοκληρώθηκε",
  "VesperTV will close now. Open it again to load your playlists.":
      "Το VesperTV θα κλείσει τώρα. Ανοίξτε το ξανά για να φορτώσουν οι λίστες σας.",
  "Enter the code shown on the other device":
      "Εισαγάγετε τον κωδικό που εμφανίζεται στην άλλη συσκευή",
  "Ready to copy": "Έτοιμο για αντιγραφή",
  "{playlists} playlists · {profiles} profiles · {favorites} favorites":
      "{playlists} λίστες · {profiles} προφίλ · {favorites} αγαπημένα",
  "This replaces the playlists, favorites and settings on this device.":
      "Αντικαθιστά τις λίστες, τα αγαπημένα και τις ρυθμίσεις σε αυτή τη συσκευή.",
  "Replace my data": "Αντικατάσταση των δεδομένων μου",
  "Enter the address shown under the code on the other device (This device: …)":
      "Εισαγάγετε τη διεύθυνση που εμφανίζεται κάτω από τον κωδικό στην άλλη συσκευή (Αυτή η συσκευή: …)",
  "Code: {code}": "Κωδικός: {code}",
  "Type the address instead": "Πληκτρολόγηση της διεύθυνσης",
  "{n} playlist": "{n} λίστα",
  "{n} playlists": "{n} λίστες",
  "{n} profile": "{n} προφίλ",
  "{n} profiles": "{n} προφίλ",
  "{n} favorite": "{n} αγαπημένο",
  "{n} favorites": "{n} αγαπημένα",
  "Clear favourites?": "Καθαρισμός αγαπημένων;",
  "Removes every starred item and favourite group from this tab's Favourites.":
      "Αφαιρεί κάθε αγαπημένο στοιχείο και αγαπημένη ομάδα από τα Αγαπημένα αυτής της καρτέλας.",
  "Favourites cleared.": "Τα αγαπημένα καθαρίστηκαν.",
  "Delete watched history?": "Διαγραφή ιστορικού παρακολούθησης;",
  "Removes the History list of live channels.":
      "Αφαιρεί τη λίστα Ιστορικού των ζωντανών καναλιών.",
  "Watched history deleted.": "Το ιστορικό παρακολούθησης διαγράφηκε.",
  "NFL RedZone channel": "Κανάλι NFL RedZone",
  "Resume {code}": "Συνέχεια {code}",
  "Play {code}": "Αναπαραγωγή {code}",
  "{n} seasons": "{n} σεζόν",
  "{n} episodes": "{n} επεισόδια",
  "1 episode": "1 επεισόδιο",
  "{m} min": "{m} λεπ.",
  "{h} h {m} min": "{h} ώ {m} λεπ.",
  "Episode {n}": "Επεισόδιο {n}",
  "Watched": "Παρακολουθήθηκε",
  "More": "Περισσότερα",
  "Watching": "Παρακολουθείτε",
  "Marked as watched": "Σημειώθηκε ως παρακολουθημένο",
  "Marked as unwatched": "Σημειώθηκε ως μη παρακολουθημένο",
  "Hold to mark as watched": "Κρατήστε για σήμανση ως παρακολουθημένο",
  "Hold to mark as unwatched": "Κρατήστε για σήμανση ως μη παρακολουθημένο",
  "Cast: {names}": "Ηθοποιοί: {names}",
  "Director: {names}": "Σκηνοθεσία: {names}",
  "Specials": "Ειδικά επεισόδια",
  "Movie and TV artwork and data may come from TMDB (The Movie Database).":
      "Εικόνες και δεδομένα ταινιών και σειρών μπορεί να προέρχονται από το TMDB (The Movie Database).",
  "{appName} {version} is available": "Το {appName} {version} είναι διαθέσιμο",
  "What's new:": "Τι νέο υπάρχει:",
  "A new version is ready to install.":
      "Μια νέα έκδοση είναι έτοιμη για εγκατάσταση.",
  "Skip this version": "Παράλειψη αυτής της έκδοσης",
  "Later": "Αργότερα",
  "See all · stats": "Όλα · στατιστικά",
  "Live games": "Ζωντανά παιχνίδια",
  "Click a game for its stats": "Κλικ σε παιχνίδι για στατιστικά",
  "No games are live right now": "Κανένα παιχνίδι δεν είναι ζωντανά τώρα",
  "RED ZONE": "RED ZONE",
  "No channel": "Χωρίς κανάλι",
  "Watch on {channel}": "Δείτε στο {channel}",
  "No channel found. Hold OK on the game in {tab} to pick one.":
      "Δεν βρέθηκε κανάλι. Κρατήστε το OK στο παιχνίδι στο {tab} για να επιλέξετε ένα.",
  "▲▼ scroll · Back closes": "▲▼ κύλιση · Πίσω για κλείσιμο",
  "Passing": "Πάσες",
  "Rushing": "Τρεξίματα",
  "Receiving": "Υποδοχές",
  "Defense": "Άμυνα",
  "Kicking": "Λακτίσματα",
  "Forwards": "Επιθετικοί",
  "Defensemen": "Αμυντικοί",
  "Goalies": "Τερματοφύλακες",
  "Batting": "Χτύπημα",
  "Pitching": "Pitching",
  "Players": "Παίκτες",
  "No stats for this game yet.":
      "Δεν υπάρχουν ακόμη στατιστικά για αυτό το παιχνίδι.",
  "Top performers": "Κορυφαίοι",
  "Injuries": "Τραυματισμοί",
  "Goals": "Γκολ",
  "pen.": "πέν.",
  "Team stats": "Στατιστικά ομάδων",
  "OK = stats · hold OK = channels · ▶❚❚ = watch":
      "OK = στατιστικά · κρατήστε OK = κανάλια · ▶❚❚ = προβολή",
  "{channel} · full screen": "{channel} · πλήρης οθόνη",
  "Add a source": "Προσθήκη πηγής",
  "Couldn't load the catalog: {error}":
      "Δεν ήταν δυνατή η φόρτωση του καταλόγου: {error}",
  "Couldn't reach that link.":
      "Δεν ήταν δυνατή η πρόσβαση σε αυτόν τον σύνδεσμο.",
  "This link failed at the provider. Choose another stream.":
      "Αυτός ο σύνδεσμος απέτυχε στον πάροχο. Επιλέξτε άλλη ροή.",
  "Menu": "Μενού",
  "No playable stream for this title.":
      "Δεν υπάρχει ροή για αναπαραγωγή αυτού του τίτλου.",
  "No sources yet.": "Δεν υπάρχουν ακόμη πηγές.",
  "None of your sources has TV shows.":
      "Καμία από τις πηγές σας δεν έχει σειρές.",
  "None of your sources has movies.":
      "Καμία από τις πηγές σας δεν έχει ταινίες.",
  "Nothing here yet.": "Δεν υπάρχει τίποτα εδώ ακόμη.",
  "Refresh": "Ανανέωση",
  "Source link (ends with manifest.json)":
      "Σύνδεσμος πηγής (τελειώνει σε manifest.json)",
  "That source is already in the list.": "Αυτή η πηγή είναι ήδη στη λίστα.",
  "This source lists no episodes for this show.":
      "Αυτή η πηγή δεν έχει επεισόδια για αυτή τη σειρά.",
  "VesperTV ships no sources. The titles you open are requested from the source you added; nothing else is shared.":
      "Το VesperTV δεν περιέχει πηγές. Οι τίτλοι που ανοίγετε ζητούνται από την πηγή που προσθέσατε· τίποτα άλλο δεν κοινοποιείται.",
  "Your sources": "Οι πηγές σας",
  "{n} TV show catalogs": "{n} κατάλογοι σειρών",
  "{n} movie catalogs": "{n} κατάλογοι ταινιών",
  "Check the link here, then press Add.":
      "Ελέγξτε τον σύνδεσμο εδώ και πατήστε Προσθήκη.",
  "Hide Movies": "Απόκρυψη Ταινιών",
  "Hide TV Shows": "Απόκρυψη Σειρών",
  "Hide Recordings": "Απόκρυψη εγγραφών",
  "Typing a key with a remote is painful. Scan this code with your phone camera and paste the key there — it appears here for you to check and save.":
      "Η πληκτρολόγηση ενός κλειδιού με τηλεχειριστήριο είναι κουραστική. Σαρώστε αυτόν τον κωδικό με την κάμερα του κινητού σας και επικολλήστε το κλειδί εκεί — εμφανίζεται εδώ για έλεγχο και αποθήκευση.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and save.":
      "Η πληκτρολόγηση ενός μεγάλου συνδέσμου με τηλεχειριστήριο είναι κουραστική. Σαρώστε αυτόν τον κωδικό με την κάμερα του κινητού σας και επικολλήστε τον σύνδεσμο εκεί — εμφανίζεται εδώ για έλεγχο και αποθήκευση.",
  "Paste the key and tap Send to TV.":
      "Επικολλήστε το κλειδί και πατήστε Αποστολή στην TV.",
  "Check it here, then press Save.": "Ελέγξτε το εδώ και πατήστε Αποθήκευση.",
  "Paste the link and tap Send to TV.":
      "Επικολλήστε τον σύνδεσμο και πατήστε Αποστολή στην TV.",
  "Removes the Movies tab and movie search results.":
      "Αφαιρεί την καρτέλα Ταινίες και τα αποτελέσματα αναζήτησης ταινιών.",
  "Removes the TV Shows tab and show search results.":
      "Αφαιρεί την καρτέλα Σειρές και τα αποτελέσματα αναζήτησης σειρών.",
  "Removes the Recordings tab.": "Αφαιρεί την καρτέλα Εγγραφές.",
  "Typing a long link with a remote is painful. Scan this code with your phone camera and paste the link there — it appears here for you to check and add.":
      "Η πληκτρολόγηση ενός μεγάλου συνδέσμου με τηλεχειριστήριο είναι κουραστική. Σαρώστε αυτόν τον κωδικό με την κάμερα του κινητού σας και επικολλήστε τον σύνδεσμο εκεί — εμφανίζεται εδώ για έλεγχο και προσθήκη.",
  "Popular": "Δημοφιλή",
  "New": "Νέα",
  "Featured": "Προτεινόμενα",
  "Search movies": "Αναζήτηση ταινιών",
  "Search TV shows": "Αναζήτηση σειρών",
  "Title": "Τίτλος",
  "Searching…": "Αναζήτηση…",
  "Clear search": "Καθαρισμός αναζήτησης",
  "Results for \"{query}\"": "Αποτελέσματα για «{query}»",
  "No results for \"{query}\"": "Κανένα αποτέλεσμα για «{query}»",
  "Choose a stream": "Επιλέξτε ροή",
  "Stream {n}": "Ροή {n}",
  "Watch tracking powered by Trakt and Simkl; VesperTV is not affiliated with or endorsed by either.":
      "Η παρακολούθηση γίνεται μέσω Trakt και Simkl· το VesperTV δεν συνδέεται ούτε εγκρίνεται από καμία από τις δύο.",
  "Powered by Trakt (trakt.tv) and Simkl (simkl.com).":
      "Με την υποστήριξη του Trakt (trakt.tv) και του Simkl (simkl.com).",
  "VesperTV is not affiliated with or endorsed by Trakt or Simkl.":
      "Το VesperTV δεν συνδέεται ούτε εγκρίνεται από το Trakt ή το Simkl.",
  "Trakt & Simkl": "Trakt & Simkl",
  "Track what you watch, lists in the Media Hub":
      "Καταγραφή όσων βλέπετε, λίστες στο Media Hub",
  "Connected as {name} — press OK to disconnect":
      "Συνδέθηκε ως {name} — πατήστε OK για αποσύνδεση",
  "Not available in this build yet":
      "Δεν είναι ακόμη διαθέσιμο σε αυτή την έκδοση",
  "Connect a watch tracker: what you watch in the Media Hub is marked as watched on your account, and your lists show up as Media Hub rows. Nothing is sent unless you connect an account.":
      "Συνδέστε μια υπηρεσία καταγραφής: ό,τι βλέπετε στο Media Hub σημειώνεται ως παρακολουθημένο στον λογαριασμό σας και οι λίστες σας εμφανίζονται ως σειρές στο Media Hub. Τίποτα δεν αποστέλλεται αν δεν συνδέσετε λογαριασμό.",
  "Watchlist and trending rows, scrobbling":
      "Σειρές λίστας παρακολούθησης και τάσεων, scrobbling",
  "Watching and plan-to-watch rows, scrobbling":
      "Σειρές «Παρακολουθώ» και «Θα δω», scrobbling",
  "Titles from your lists play through your stream add-ons (Media Hub sources), by IMDb id. Only titles with an IMDb id are reported.":
      "Οι τίτλοι των λιστών σας παίζουν μέσω των πρόσθετων ροών σας (πηγές Media Hub), με βάση το IMDb id. Αναφέρονται μόνο τίτλοι με IMDb id.",
  "{name} connected.": "Το {name} συνδέθηκε.",
  "Disconnect {name}?": "Αποσύνδεση του {name};",
  "Its rows leave the Media Hub and plays are no longer reported. Your account itself is untouched.":
      "Οι σειρές του φεύγουν από το Media Hub και οι αναπαραγωγές δεν αναφέρονται πλέον. Ο λογαριασμός σας δεν επηρεάζεται.",
  "Disconnect": "Αποσύνδεση",
  "Couldn't reach {name}. Check the connection.":
      "Δεν ήταν δυνατή η σύνδεση με το {name}. Ελέγξτε τη σύνδεση.",
  "The code expired. Try again.": "Ο κωδικός έληξε. Δοκιμάστε ξανά.",
  "Sign-in was not completed. Try again.":
      "Η σύνδεση δεν ολοκληρώθηκε. Δοκιμάστε ξανά.",
  "Connect {name}": "Σύνδεση {name}",
  "On your phone or computer, open":
      "Στο κινητό ή τον υπολογιστή σας, ανοίξτε το",
  "and enter this code:": "και εισαγάγετε αυτόν τον κωδικό:",
  "Waiting for you to approve…": "Αναμονή για την έγκρισή σας…",
  "Try again": "Δοκιμάστε ξανά",
  "Trakt watchlist": "Λίστα παρακολούθησης Trakt",
  "Trending on Trakt": "Τάσεις στο Trakt",
  "Watching on Simkl": "Παρακολουθώ στο Simkl",
  "Simkl plan to watch": "Θα δω στο Simkl",
  "{n} channels": "{n} κανάλια",
  "No live games on your channels right now":
      "Κανένα ζωντανό παιχνίδι στα κανάλια σας αυτή τη στιγμή",
  "Connect Jellyfin / Emby": "Σύνδεση Jellyfin / Emby",
  "User name": "Όνομα χρήστη",
  "Connect": "Σύνδεση",
  "Enter the server address and your user name.":
      "Εισαγάγετε τη διεύθυνση του διακομιστή και το όνομα χρήστη σας.",
  "Wrong user name or password.": "Λάθος όνομα χρήστη ή κωδικός.",
  "This account has no movie or TV library.":
      "Αυτός ο λογαριασμός δεν έχει βιβλιοθήκη ταινιών ή σειρών.",
  "Couldn't find a Jellyfin or Emby server at that address.":
      "Δεν βρέθηκε διακομιστής Jellyfin ή Emby σε αυτή τη διεύθυνση.",
  "Sign in to your own Jellyfin or Emby server: its movie and TV libraries show up in the Media Hub. Files play as they are stored on the server (no transcoding).":
      "Συνδεθείτε στον δικό σας διακομιστή Jellyfin ή Emby: οι βιβλιοθήκες ταινιών και σειρών του εμφανίζονται στο Media Hub. Τα αρχεία παίζουν όπως είναι αποθηκευμένα στον διακομιστή (χωρίς μετακωδικοποίηση).",
  "Your password is only sent to your server. VesperTV keeps the sign-in token the server gives back, not the password.":
      "Ο κωδικός σας στέλνεται μόνο στον διακομιστή σας. Το VesperTV κρατά το διακριτικό σύνδεσης που επιστρέφει ο διακομιστής, όχι τον κωδικό.",
  "Media Hub": "Media Hub",
  "Media Hub sources": "Πηγές Media Hub",
  "Add-on sources for the Media Hub tab":
      "Πηγές πρόσθετων για την καρτέλα Media Hub",
  "Clear Media Hub?": "Καθαρισμός Media Hub;",
  "Clear Media Hub": "Καθαρισμός Media Hub",
  "Media Hub cleared.": "Το Media Hub καθαρίστηκε.",
  "Include Media Hub tab data": "Συμπερίληψη δεδομένων της καρτέλας Media Hub",
  "Media Hub sources and their watch progress are sent too":
      "Στέλνονται επίσης οι πηγές Media Hub και η πρόοδος παρακολούθησής τους",
  "The other device keeps its own Media Hub sources":
      "Η άλλη συσκευή κρατά τις δικές της πηγές Media Hub",
  "Add a source to browse films and series. Any source that follows the catalog/stream add-on format works.":
      "Προσθέστε μια πηγή για περιήγηση σε ταινίες και σειρές. Λειτουργεί κάθε πηγή που ακολουθεί τη μορφή πρόσθετων κατάλογος/ροή.",
  "That link isn't a Media Hub source (it needs movie or series streams).":
      "Αυτός ο σύνδεσμος δεν είναι πηγή Media Hub (χρειάζεται ροές ταινιών ή σειρών).",
  "Removes every Media Hub source and its saved catalog from this device.":
      "Αφαιρεί κάθε πηγή Media Hub και τον αποθηκευμένο κατάλογό της από αυτή τη συσκευή.",
  "The Media Hub tab shows films and series from sources you add here. Any source that follows the catalog/stream add-on format works; a source that only offers streams by IMDb id gets its posters and episodes from Cinemeta. Only direct video links are played; torrent links are ignored.":
      "Η καρτέλα Media Hub δείχνει ταινίες και σειρές από πηγές που προσθέτετε εδώ. Λειτουργεί κάθε πηγή που ακολουθεί τη μορφή πρόσθετων κατάλογος/ροή· μια πηγή που προσφέρει μόνο ροές με IMDb id παίρνει αφίσες και επεισόδια από το Cinemeta. Παίζουν μόνο άμεσοι σύνδεσμοι βίντεο· οι σύνδεσμοι torrent αγνοούνται.",
  "Hide Media Hub": "Απόκρυψη Media Hub",
  "Removes the Media Hub tab.": "Αφαιρεί την καρτέλα Media Hub.",
  "Hide Multiview": "Απόκρυψη Multiview",
  "Removes the Multiview row and the player's Open in Multiview button.":
      "Αφαιρεί τη σειρά Multiview και το κουμπί «Άνοιγμα σε Multiview» του player.",
  "Genre": "Είδος",
  "All genres": "Όλα τα είδη",
  "genre.Action": "Δράση",
  "genre.Adventure": "Περιπέτεια",
  "genre.Animation": "Κινούμενα σχέδια",
  "genre.Biography": "Βιογραφία",
  "genre.Comedy": "Κωμωδία",
  "genre.Crime": "Έγκλημα",
  "genre.Documentary": "Ντοκιμαντέρ",
  "genre.Drama": "Δράμα",
  "genre.Family": "Οικογενειακή",
  "genre.Fantasy": "Φαντασίας",
  "genre.History": "Ιστορική",
  "genre.Horror": "Τρόμου",
  "genre.Mystery": "Μυστηρίου",
  "genre.Romance": "Ρομαντική",
  "genre.Sci-Fi": "Επιστημονική φαντασία",
  "genre.Sport": "Αθλητική",
  "genre.Thriller": "Θρίλερ",
  "genre.War": "Πολεμική",
  "genre.Western": "Γουέστερν",
  "genre.Reality-TV": "Ριάλιτι",
  "genre.Talk-Show": "Talk show",
  "genre.Game-Show": "Τηλεπαιχνίδι",
  "OK: show/hide or add · Hold OK: favourite league, or send an added league back to the bank":
      "OK: εμφάνιση/απόκρυψη ή προσθήκη · Κρατήστε OK: αγαπημένο πρωτάθλημα ή επιστροφή ενός προστιθέμενου πρωταθλήματος στην τράπεζα",
  "Make favourite league": "Ορισμός ως αγαπημένο πρωτάθλημα",
  "Remove from favourite": "Αφαίρεση από αγαπημένο",
  "{tab} opens on it and its games come first in Live now":
      "Το {tab} ανοίγει σε αυτό και τα παιχνίδια του έρχονται πρώτα στα Ζωντανά τώρα",
  "Send back to the league bank": "Επιστροφή στην τράπεζα πρωταθλημάτων",
  "Favourite league": "Αγαπημένο πρωτάθλημα",
  "◀ ▶ tabs  ·  OK to watch  ·  Hold OK for stats  ·  Back to close":
      "◀ ▶ καρτέλες  ·  OK για προβολή  ·  Κρατήστε OK για στατιστικά  ·  Πίσω για κλείσιμο",
  "Click the game again or Enter: full screen  ·  Esc: stop":
      "Κλικ ξανά στο παιχνίδι ή Enter: πλήρης οθόνη  ·  Esc: διακοπή",
  "Click again: watch here  ·  Hold: pick the channel":
      "Κλικ ξανά: προβολή εδώ  ·  Παρατεταμένο: επιλογή καναλιού",
  "Movie genres": "Είδη ταινιών",
  "TV show genres": "Είδη σειρών",
  "Recently watched": "Πρόσφατα",
  "Clear recent searches": "Καθαρισμός πρόσφατων αναζητήσεων",
  // Data pool (player stream details, Settings > General)
  "Data pool": "Data pool",
  "Data pool display": "Εμφάνιση Data pool",
  "Press OK while a live channel plays to open a second card under the channel info with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Πατήστε OK ενώ παίζει ένα ζωντανό κανάλι για να ανοίξει μια δεύτερη κάρτα κάτω από τις πληροφορίες του καναλιού με τα στοιχεία της ροής: ανάλυση, καρέ ανά δευτερόλεπτο, codecs, bitrate, εκδόσεις ποιότητας, κομμάτια ήχου, buffer και HDR. Απενεργοποιημένο: το OK δείχνει μόνο τις πληροφορίες του καναλιού.",
  "Reading the stream…": "Ανάγνωση της ροής…",
  "Video": "Βίντεο",
  "Video bitrate": "Bitrate βίντεο",
  "Picture": "Εικόνα",
  "Quality variants": "Εκδόσεις ποιότητας",
  "One (not adaptive)": "Μία (όχι προσαρμοστική)",
  "Audio": "Ήχος",
  "Audio tracks": "Κομμάτια ήχου",
  "Stream": "Ροή",
  "Buffered": "Στο buffer",
  "{seconds} s": "{seconds} δ",
  "State": "Κατάσταση",
  "Buffering…": "Φόρτωση buffer…",
  "Playing for {time}": "Παίζει εδώ και {time}",
  "Paused": "Σε παύση",
  "Device HDR": "HDR συσκευής",
  "Not reported by the stream": "Δεν αναφέρεται από τη ροή",
  "Mono": "Μονοφωνικό",
  "Stereo": "Στερεοφωνικό",
  "Direct stream": "Άμεση ροή",
  "Yes": "Ναι",
  "No": "Όχι",
  "Stream bitrate": "Bitrate ροής",
  "Declared bitrate": "Δηλωμένο bitrate",
  "Dropped frames": "Χαμένα καρέ",
  "(measured)": "(μετρημένο)",
  "Measuring…": "Μέτρηση…",
  // Settings categories (left panel)
  "Playlists & guide": "Λίστες και οδηγός",
  "Your playlists and their logins, the TV guide (EPG) and the viewer profiles.":
      "Οι λίστες σας και τα στοιχεία σύνδεσής τους, ο οδηγός TV (EPG) και τα προφίλ.",
  "Everything the Media Hub uses: its add-on sources, online subtitles, Trakt & Simkl watch tracking and the optional TMDB key.":
      "Ό,τι χρησιμοποιεί το Media Hub: πηγές add-on, online υπότιτλοι, παρακολούθηση Trakt και Simkl και το προαιρετικό κλειδί TMDB.",
  "Interface": "Διεπαφή",
  "How the app looks and what it shows: theme, tabs, matching the TV's frame rate, the player's extras and reminders.":
      "Η εμφάνιση της εφαρμογής και τι δείχνει: θέμα, καρτέλες, ρυθμός καρέ της τηλεόρασης, έξτρα του player και υπενθυμίσεις.",
  "Hide Movies, TV Shows, Media Hub, Recordings or Multiview":
      "Απόκρυψη Ταινιών, Σειρών, Media Hub, Εγγραφών ή Multiview",
  "Fixes for the picture on some Fire TV sticks":
      "Διορθώσεις για την εικόνα σε ορισμένα Fire TV stick",
  "Dolby Atmos to your soundbar or receiver":
      "Dolby Atmos στο soundbar ή στον δέκτη σας",
  "Surround passthrough (Dolby Atmos)": "Απευθείας surround ήχος (Dolby Atmos)",
  "Sends Dolby Digital, Dolby Atmos and DTS sound to your soundbar or receiver untouched (HDMI passthrough), so it can play Atmos. Off: this device turns that sound into plain stereo/5.1 first, so Atmos is lost. While on, the volume of that sound is set on your TV or receiver only, and if you hear nothing on a channel, turn this off. Multiview always uses plain sound (passthrough there kept muted screens playing). Applies from the next channel.":
      "Στέλνει τον ήχο Dolby Digital, Dolby Atmos και DTS αυτούσιο στο soundbar ή στον δέκτη σας (HDMI passthrough), ώστε να παίζει Atmos. Ανενεργό: η συσκευή μετατρέπει πρώτα αυτόν τον ήχο σε απλό στερεοφωνικό/5.1 και το Atmos χάνεται. Όταν είναι ενεργό, η ένταση αυτού του ήχου ρυθμίζεται μόνο από την τηλεόραση ή τον δέκτη, και αν δεν ακούτε τίποτα σε ένα κανάλι, απενεργοποιήστε το. Το Multiview χρησιμοποιεί πάντα απλό ήχο (εκεί το passthrough άφηνε τις σιγασμένες οθόνες να παίζουν). Ισχύει από το επόμενο κανάλι.",
  "Stream details when you press OK on a channel":
      "Λεπτομέρειες ροής όταν πατάτε OK σε ένα κανάλι",
  "One list for every playlist, or one per playlist":
      "Μία λίστα για όλες τις λίστες, ή μία ανά λίστα",
  "The connections tip when opening Multiview":
      "Η συμβουλή για τις συνδέσεις όταν ανοίγει το Multiview",
  "The \"Hold > to resume\" pill": "Η ένδειξη «Κρατήστε > για συνέχεια»",
  "Language and clock, what plays when the app starts, Fast startup, and clearing your history.":
      "Γλώσσα και ρολόι, τι παίζει στην εκκίνηση, Γρήγορη εκκίνηση και διαγραφή ιστορικού.",
  "App language and 24-hour clock": "Γλώσσα εφαρμογής και ρολόι 24 ωρών",
  "Resume the last channel, Fast startup":
      "Συνέχεια του τελευταίου καναλιού, Γρήγορη εκκίνηση",
  "Clear searches, channels, Continue Watching":
      "Διαγραφή αναζητήσεων, καναλιών, Συνέχεια παρακολούθησης",
  "Device & data": "Συσκευή και δεδομένα",
  "Move your whole setup to another device, keep a backup of it, and update VesperTV.":
      "Μεταφέρετε όλη τη ρύθμισή σας σε άλλη συσκευή, κρατήστε αντίγραφο ασφαλείας και ενημερώστε το VesperTV.",
  // Own live groups (Move to group)
  "Move to group…": "Μετακίνηση σε ομάδα…",
  "Move {name} to": "Μετακίνηση του {name} σε",
  "New group…": "Νέα ομάδα…",
  "Back to {group}": "Επιστροφή στο {group}",
  "New group": "Νέα ομάδα",
  "Group name": "Όνομα ομάδας",
  "{name} is now in {group}": "Το {name} είναι τώρα στο {group}",
  "Delete this group": "Διαγραφή αυτής της ομάδας",
  "{group} deleted. Its channels are back in their groups.":
      "Η ομάδα {group} διαγράφηκε. Τα κανάλια της επέστρεψαν στις ομάδες τους.",
  // Fast startup
  "Fast startup": "Γρήγορη εκκίνηση",
  "Opens the app without waiting for Movies and TV Shows to load; they fill in a few seconds later. For fast devices — leave it off on an older box if the app closes by itself right after starting. Applies from the next start.":
      "Ανοίγει την εφαρμογή χωρίς να περιμένει να φορτώσουν οι Ταινίες και οι Σειρές· συμπληρώνονται λίγα δευτερόλεπτα αργότερα. Για γρήγορες συσκευές — αφήστε το κλειστό σε παλιότερο αποκωδικοποιητή αν η εφαρμογή κλείνει μόνη της αμέσως μετά την εκκίνηση. Ισχύει από την επόμενη εκκίνηση.",
  // Group hold menu: New group
  "{group} created. Hold OK on a channel > Move to group… to add channels.":
      "Η ομάδα {group} δημιουργήθηκε. Κρατήστε OK σε ένα κανάλι > Μετακίνηση σε ομάδα… για να προσθέσετε κανάλια.",
  // Channel menu: Remove from group
  "Remove from {group}": "Αφαίρεση από το {group}",
  // Settings > Device & data > Send log
  "Send log": "Αποστολή αρχείου καταγραφής",
  "Send the app's log to the developer":
      "Στείλτε το αρχείο καταγραφής της εφαρμογής στον προγραμματιστή",
  "Sending...": "Αποστολή...",
  "Send again": "Αποστολή ξανά",
  "Log sent. Your code:": "Το αρχείο στάλθηκε. Ο κωδικός σας:",
  "Mention this code on Reddit or Discord with what happened, so the developer can find your log.":
      "Αναφέρετε αυτόν τον κωδικό στο Reddit ή στο Discord μαζί με ό,τι συνέβη, ώστε ο προγραμματιστής να βρει το αρχείο σας.",
  "Something not working? Send the app's log to the VesperTV developer. It holds what the app did recently (this session and the last one) and your device model, nothing else.":
      "Κάτι δεν λειτουργεί; Στείλτε το αρχείο καταγραφής της εφαρμογής στον προγραμματιστή του VesperTV. Περιέχει τι έκανε πρόσφατα η εφαρμογή (αυτή και την προηγούμενη συνεδρία) και το μοντέλο της συσκευής σας, τίποτα άλλο.",
  "Server addresses, user names, passwords and other private details are removed before sending.":
      "Διευθύνσεις διακομιστών, ονόματα χρήστη, κωδικοί και άλλα προσωπικά στοιχεία αφαιρούνται πριν την αποστολή.",
  "Too many logs sent from here. Try again in an hour.":
      "Στάλθηκαν πάρα πολλά αρχεία από εδώ. Δοκιμάστε ξανά σε μία ώρα.",
  "Couldn't send the log. Check the internet connection and try again.":
      "Δεν ήταν δυνατή η αποστολή. Ελέγξτε τη σύνδεση στο Internet και δοκιμάστε ξανά.",
  // Recordings (Sports Trak recording, Recordings tab)
  "Watch live": "Παρακολούθηση ζωντανά",
  "Play from the start": "Αναπαραγωγή από την αρχή",
  "What has been recorded so far": "Ό,τι έχει εγγραφεί μέχρι τώρα",
  "Stop recording": "Διακοπή εγγραφής",
  "Keeps what has been recorded": "Κρατά ό,τι έχει εγγραφεί",
  "Cancel recording": "Ακύρωση εγγραφής",
  "Delete recording": "Διαγραφή εγγραφής",
  "Frees {size}": "Ελευθερώνει {size}",
  "Removes it from the list": "Την αφαιρεί από τη λίστα",
  "Recordings": "Εγγραφές",
  "Recording every {team} game": "Εγγράφεται κάθε αγώνας της {team}",
  "Nothing recorded yet. Hold OK on a game in {tab} and pick Record, or hold OK on a live channel.":
      "Δεν υπάρχουν εγγραφές ακόμα. Κρατήστε OK σε έναν αγώνα στο {tab} και επιλέξτε Εγγραφή, ή κρατήστε OK σε ένα ζωντανό κανάλι.",
  "Recording now": "Εγγράφεται τώρα",
  "Recorded": "Εγγεγραμμένα",
  "{used} of {cap} GB used": "{used} από {cap} GB σε χρήση",
  "REC · {size}": "REC · {size}",
  "Waiting for a channel": "Αναμονή για κανάλι",
  "Interrupted · {size}": "Διακόπηκε · {size}",
  "Missed": "Χάθηκε",
  "Failed": "Απέτυχε",
  "Live channel": "Ζωντανό κανάλι",
  "Start early: {min} min": "Έναρξη νωρίτερα: {min} λεπτά",
  "Before the game's scheduled start":
      "Πριν την προγραμματισμένη έναρξη του αγώνα",
  "Keep recording: {min} min": "Συνέχιση εγγραφής: {min} λεπτά",
  "After the scheduled end, for overtime and delays":
      "Μετά το προγραμματισμένο τέλος, για παράταση και καθυστερήσεις",
  "Space for recordings: {gb} GB": "Χώρος για εγγραφές: {gb} GB",
  "{used} used. Recording stops when this is full or the storage has less than 1 GB left.":
      "{used} σε χρήση. Η εγγραφή σταματά όταν γεμίσει ή μείνει λιγότερο από 1 GB.",
  "Save recordings to": "Αποθήκευση εγγραφών σε",
  "USB drive / SD card": "USB / κάρτα SD",
  "This device": "Αυτή η συσκευή",
  "{free} free of {total}": "{free} ελεύθερα από {total}",
  "Plug in a USB drive or SD card to record to it. Recordings on this device are deleted if VesperTV is uninstalled.":
      "Συνδέστε USB ή κάρτα SD για εγγραφή εκεί. Οι εγγραφές σε αυτή τη συσκευή διαγράφονται αν απεγκατασταθεί το VesperTV.",
  "Recording in progress": "Εγγραφή σε εξέλιξη",
  "{title} is recording on {channel}. Your playlist allows one connection, so playing another of its channels stops the recording.":
      "Το {title} εγγράφεται στο {channel}. Η λίστα σας επιτρέπει μία σύνδεση, οπότε η αναπαραγωγή άλλου καναλιού της σταματά την εγγραφή.",
  "Recording cancelled": "Η εγγραφή ακυρώθηκε",
  "Not enough free space to record": "Δεν υπάρχει αρκετός χώρος για εγγραφή",
  "Recording {title}": "Εγγραφή: {title}",
  "{title} will be recorded": "Το {title} θα εγγραφεί",
  "No longer recording every {team} game":
      "Οι αγώνες της {team} δεν εγγράφονται πια",
  "Every {team} game will be recorded": "Κάθε αγώνας της {team} θα εγγράφεται",
  "Waiting for a channel in the guide": "Αναμονή για κανάλι στον οδηγό",
  "Record": "Εγγραφή",
  "{channel} · starts now": "{channel} · ξεκινά τώρα",
  "{channel} · from {time}": "{channel} · από τις {time}",
  "Stop recording every {team} game": "Διακοπή εγγραφής κάθε αγώνα της {team}",
  "Record every {team} game": "Εγγραφή κάθε αγώνα της {team}",
  "Recordings already made are kept": "Οι εγγραφές που έγιναν διατηρούνται",
  "One team at a time, on the channel {tab} picks":
      "Μία ομάδα τη φορά, στο κανάλι που επιλέγει το {tab}",
  "Replaces {team}": "Αντικαθιστά την {team}",
  "Recording stopped": "Η εγγραφή σταμάτησε",
  "Margins, space and where recordings are saved":
      "Περιθώρια, χώρος και θέση αποθήκευσης",
  "Record until the show ends": "Εγγραφή μέχρι το τέλος της εκπομπής",
  "Record until I stop it": "Εγγραφή μέχρι να τη σταματήσω",
  "Keeps going across shows (4 hours at most)":
      "Συνεχίζει από εκπομπή σε εκπομπή (έως 4 ώρες)",
  "{title} · stops at {time}": "{title} · σταματά στις {time}",
  "No guide for this channel: stops after 2 hours":
      "Χωρίς οδηγό για αυτό το κανάλι: σταματά μετά από 2 ώρες",
  // Media Hub: Ready tag / Debrid accounts
  "Cleared": "Διαγράφηκε",
  "Saved — key verified ✓": "Αποθηκεύτηκε — το κλειδί επαληθεύτηκε ✓",
  "Saved, but {service} rejected the key — double-check it":
      "Αποθηκεύτηκε, αλλά το {service} απέρριψε το κλειδί — ελέγξτε το",
  "Debrid accounts": "Λογαριασμοί debrid",
  "Optional keys for the \"Ready\" tag":
      "Προαιρετικά κλειδιά για την ετικέτα «Έτοιμο»",
  "Some Media Hub sources answer Play with a short \"being downloaded\" video while they fetch a title into your debrid account. VesperTV then checks back every minute and puts a \"Ready\" tag on the title's poster once it's there.":
      "Ορισμένες πηγές του Media Hub απαντούν στην Αναπαραγωγή με ένα σύντομο βίντεο «γίνεται λήψη» ενώ φέρνουν έναν τίτλο στον λογαριασμό σας debrid. Το VesperTV ελέγχει ξανά κάθε λεπτό και βάζει την ετικέτα «Έτοιμο» στην αφίσα του τίτλου μόλις είναι διαθέσιμος.",
  "Optional: with your own key, your account confirms it directly. Without one, VesperTV asks the source again until the full file answers.":
      "Προαιρετικό: με το δικό σας κλειδί, ο λογαριασμός σας το επιβεβαιώνει απευθείας. Χωρίς κλειδί, το VesperTV ρωτά ξανά την πηγή μέχρι να απαντήσει το πλήρες αρχείο.",
  "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (API key). Kept in VesperTV and only used to read your downloads list.":
      "Real-Debrid: real-debrid.com/apitoken. TorBox: torbox.app/settings (κλειδί API). Φυλάσσεται στο VesperTV και χρησιμοποιείται μόνο για την ανάγνωση της λίστας λήψεών σας.",
  "Real-Debrid API token": "Διακριτικό API Real-Debrid",
  "TorBox API key": "Κλειδί API TorBox",
  // Sports Trak: League bank heading for college conferences
  "College": "Κολεγιακά",
  // Settings > General > Support VesperTV
  "Support VesperTV": "Υποστηρίξτε το VesperTV",
  "How you can help":
      "Πώς μπορείτε να βοηθήσετε",
  "VesperTV is free and always will be: no ads, no tracking, no paid features. The support page shows how you can help pay for the server, the website and development.":
      "Το VesperTV είναι δωρεάν και θα είναι πάντα: χωρίς διαφημίσεις, χωρίς παρακολούθηση, χωρίς επί πληρωμή λειτουργίες. Η σελίδα υποστήριξης δείχνει πώς μπορείτε να βοηθήσετε να καλυφθούν ο διακομιστής, ο ιστότοπος και η ανάπτυξη.",
  "Supporting is a thank-you, never a paywall: everyone gets the same app.":
      "Η υποστήριξη είναι ένα ευχαριστώ, ποτέ πληρωμή για πρόσβαση: όλοι έχουν την ίδια εφαρμογή.",
  // Settings > General > Remote tips
  "Language and clock, what plays when the app starts, Fast startup, clearing your history, and remote tips.":
      "Γλώσσα και ρολόι, τι παίζει στην εκκίνηση, Γρήγορη εκκίνηση, διαγραφή ιστορικού και συμβουλές τηλεχειριστηρίου.",
  "Remote tips": "Συμβουλές τηλεχειριστηρίου",
  "Every hold menu and shortcut, on your phone":
      "Κάθε μενού παρατεταμένου πατήματος και συντόμευση, στο κινητό σας",
  "Every hold menu and remote shortcut, on one page: hold OK on channels, groups and posters, the side panel on ← in full screen, Multiview, Sports Trak and more.":
      "Κάθε μενού παρατεταμένου πατήματος και συντόμευση του τηλεχειριστηρίου σε μία σελίδα: κρατήστε πατημένο το OK σε κανάλια, ομάδες και αφίσες, το πλαϊνό πάνελ με ← σε πλήρη οθόνη, Multiview, Sports Trak και άλλα.",
  "Scan with your phone, or open": "Σαρώστε με το κινητό σας ή ανοίξτε",
  "Open": "Άνοιγμα",
  "The basics: hold OK (about half a second) opens a menu almost everywhere. Back always steps out one level. OK twice on a channel = full screen.":
      "Τα βασικά: κρατώντας πατημένο το OK (περίπου μισό δευτερόλεπτο) ανοίγει μενού σχεδόν παντού. Το Πίσω βγαίνει πάντα ένα επίπεδο. OK δύο φορές σε κανάλι = πλήρης οθόνη.",
  "Fetching…": "Λήψη…",
  // Media Hub: list-only sources
  "Plays through your other sources": "Αναπαράγεται μέσω των άλλων πηγών σας",
  // Search: Media Hub results
  "Search Live TV, Movies, TV Shows & the Media Hub":
      "Αναζήτηση σε ζωντανή TV, ταινίες, σειρές και στο Media Hub",
  // Player: what an unreadable link really served
  "This file's format can't be played here. Try another stream (an MKV or MP4 one).":
      "Η μορφή αυτού του αρχείου δεν μπορεί να αναπαραχθεί εδώ. Δοκιμάστε άλλη ροή (MKV ή MP4).",
  "Your source sent a message instead of the video:":
      "Η πηγή σας έστειλε μήνυμα αντί για το βίντεο:",
  "Check your source or debrid account (plan limits, active downloads), or pick another stream.":
      "Ελέγξτε την πηγή ή τον λογαριασμό debrid (όρια πακέτου, ενεργές λήψεις) ή επιλέξτε άλλη ροή.",
  // Media Hub: import add-ons (pasted links, Stremio)
  "Added to the Media Hub: {names}": "Προστέθηκε στο Media Hub: {names}",
  "Added to subtitle add-ons: {names}":
      "Προστέθηκε στα πρόσθετα υποτίτλων: {names}",
  "Already added: {names}": "Έχει ήδη προστεθεί: {names}",
  "Not usable in VesperTV: {names}":
      "Δεν χρησιμοποιείται στο VesperTV: {names}",
  "Couldn't reach: {names}": "Δεν ήταν δυνατή η πρόσβαση: {names}",
  "Import from Stremio": "Εισαγωγή από το Stremio",
  "Couldn't reach Stremio. Check your internet connection.":
      "Δεν ήταν δυνατή η σύνδεση με το Stremio. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο.",
  "Couldn't read your Stremio add-ons. Try again.":
      "Δεν ήταν δυνατή η ανάγνωση των πρόσθετων Stremio. Δοκιμάστε ξανά.",
  "Copy the add-ons from your Stremio account. Nothing is changed on your Stremio account.":
      "Αντιγράψτε τα πρόσθετα από τον λογαριασμό σας Stremio. Τίποτα δεν αλλάζει στον λογαριασμό σας.",
  "On your phone, scan the code or open":
      "Στο κινητό σας, σαρώστε τον κωδικό ή ανοίξτε",
  "Code": "Κωδικός",
  "Then sign in to Stremio there. This page continues on its own.":
      "Μετά συνδεθείτε στο Stremio εκεί. Αυτή η σελίδα συνεχίζει μόνη της.",
  "Your Stremio account has no add-ons VesperTV can copy.":
      "Ο λογαριασμός σας Stremio δεν έχει πρόσθετα που μπορεί να αντιγράψει το VesperTV.",
  "Your Stremio add-ons. Untick any you don't want.":
      "Τα πρόσθετα Stremio σας. Αποεπιλέξτε όσα δεν θέλετε.",
  "Add {n} add-ons": "Προσθήκη {n} πρόσθετων",
  "Already added": "Έχει ήδη προστεθεί",
  "Can't play in VesperTV": "Δεν μπορεί να αναπαραχθεί στο VesperTV",
  "Several links at once work too.": "Λειτουργούν και πολλοί σύνδεσμοι μαζί.",
  "{n} links checked": "Ελέγχθηκαν {n} σύνδεσμοι",
  // Data pool on movies / episodes
  "Press OK while a channel, movie or episode plays to open a card with the stream's details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.":
      "Πατήστε OK ενώ παίζει κανάλι, ταινία ή επεισόδιο για να ανοίξει μια κάρτα με τις λεπτομέρειες της ροής: ανάλυση, καρέ ανά δευτερόλεπτο, codecs, bitrate, παραλλαγές ποιότητας, κομμάτια ήχου, buffer και HDR. Απενεργοποιημένο: το OK δείχνει μόνο τις πληροφορίες του καναλιού.",
  "Stream details when you press OK while watching":
      "Λεπτομέρειες ροής όταν πατάτε OK κατά την προβολή",
  // CFL official feed
  'East Division': 'Ανατολική περιφέρεια',
  'West Division': 'Δυτική περιφέρεια',
  'Score unavailable': 'Μη διαθέσιμο σκορ',
  'Passing yards': 'Γιάρδες πάσας',
  'Rushing yards': 'Γιάρδες τρεξίματος',
  'Net offence': 'Καθαρή επίθεση',
  'First downs': 'Πρώτα down',
  'Sacks': 'Sack',
  '2nd down conversions': 'Μετατροπές 2ου down',
  'Turnovers': 'Απώλειες κατοχής',
  'Penalties (yards)': 'Ποινές (γιάρδες)',
  'Field goals': 'Field goals',
  'Time of possession': 'Χρόνος κατοχής',
  'Punting': 'Punt',
  'Kickoffs': 'Kickoff',
  'Kickoff returns': 'Επιστροφές kickoff',
  'Punt returns': 'Επιστροφές punt',

  "Pick channels myself": "Επιλογή καναλιών",
  "All groups": "Όλες οι ομάδες",
  "{count} selected": "{count} επιλεγμένα",
  "Select results": "Επιλογή αποτελεσμάτων",
  "Clear results": "Αποεπιλογή αποτελεσμάτων",
  "Browse all channels": "Περιήγηση σε όλα τα κανάλια",
  "My sports channels": "Τα αθλητικά μου κανάλια",
  "List name": "Όνομα λίστας",
  "Add to list": "Προσθήκη στη λίστα",
  "Create list": "Δημιουργία λίστας",
  "Edit list": "Επεξεργασία λίστας",
  "Versions": "Εκδόσεις",
  "My lists": "Οι λίστες μου",
  "League networks": "Κανάλια πρωταθλημάτων",
  "Sports networks": "Αθλητικά κανάλια",
  "Regional channels": "Περιφερειακά κανάλια",
  "Channels": "Κανάλια",
  "Games": "Αγώνες",
  "Use a playlist group": "Χρήση ομάδας λίστας αναπαραγωγής",
  "Rename list": "Μετονομασία λίστας",
  "Delete list": "Διαγραφή λίστας",

  "Filters": "Φίλτρα",
  "Edit tags": "Επεξεργασία ετικετών",
  "Country": "Χώρα",
  "Network": "Δίκτυο",
  "Sport": "Άθλημα",
  "League": "Πρωτάθλημα",
  "Group": "Ομάδα",
  "Unknown": "Άγνωστο",
  "Clear all": "Εκκαθάριση όλων",
  "Keep this list updated": "Διατήρηση ενημερωμένης λίστας",
  "Comma-separated tags": "Ετικέτες χωρισμένες με κόμματα",
  "Add sources": "Προσθήκη πηγών",
  "More sources": "Περισσότερες πηγές",
  "Your added source": "Η πηγή που προσθέσατε",
  "This game": "Αυτός ο αγώνας",
  "hockey": "Χόκεϊ",
  "basketball": "Μπάσκετ",
  "football": "Αμερικανικό ποδόσφαιρο",
  "soccer": "Ποδόσφαιρο",
  "baseball": "Μπέιζμπολ",
  "tennis": "Τένις",
  "golf": "Γκολφ",
  "racing": "Μηχανοκίνητος αθλητισμός",

  "Trailer": "Τρέιλερ",
  "Cast": "Ηθοποιοί",
  "Unable to open trailer": "Δεν ήταν δυνατό το άνοιγμα του τρέιλερ",
  "Next episode airs {date}": "Το επόμενο επεισόδιο προβάλλεται στις {date}",
  "Next episode: {code} · {date}": "Επόμενο επεισόδιο: {code} · {date}",
  "YouTube playback needs Android System WebView or Microsoft Edge WebView2.":
      "Η αναπαραγωγή YouTube απαιτεί Android System WebView ή Microsoft Edge WebView2.",
  "YouTube could not play this video ({code}).":
      "Το YouTube δεν μπορεί να αναπαράγει αυτό το βίντεο ({code}).",
  "Open in YouTube": "Άνοιγμα στο YouTube",
  "Back 10 seconds": "Πίσω 10 δευτερόλεπτα",
  "Forward 10 seconds": "Μπροστά 10 δευτερόλεπτα",
  "Play / pause": "Αναπαραγωγή / παύση",
  "Mark season watched": "Σήμανση σεζόν ως προβληθείσας",
  "Mark season unwatched": "Σήμανση σεζόν ως μη προβληθείσας",
  "Season {season} marked as watched":
      "Η σεζόν {season} σημάνθηκε ως προβληθείσα",
  "Season {season} marked as unwatched":
      "Η σεζόν {season} σημάνθηκε ως μη προβληθείσα",
  "Colour": "Χρώμα",
  "Kids profile": "Παιδικό προφίλ",
  "Photo": "Φωτογραφία",
  "Profile": "Προφίλ",
  "Actions": "Ενέργειες",
  "Active": "Ενεργό",
  "Kids & PIN": "Παιδιά και PIN",
  "Scan with your phone to add a photo":
      "Σαρώστε με το τηλέφωνό σας για προσθήκη φωτογραφίας",
  "Choose a photo": "Επιλογή φωτογραφίας",
  "Remove photo": "Αφαίρεση φωτογραφίας",
  "Choose a photo and tap Send to TV.":
      "Επιλέξτε φωτογραφία και πατήστε Αποστολή στην TV.",
  "Your photo appears here automatically.":
      "Η φωτογραφία εμφανίζεται εδώ αυτόματα.",
  "Could not read photo. Choose a JPEG or PNG under 2 MB.":
      "Αδυναμία ανάγνωσης φωτογραφίας. Επιλέξτε JPEG ή PNG μικρότερο από 2 MB.",
  "Could not save profile. Try again.":
      "Αδυναμία αποθήκευσης προφίλ. Δοκιμάστε ξανά.",
  "Watch history": "Ιστορικό προβολής",
  "Hidden groups and channels": "Κρυφές ομάδες και κανάλια",
  "Home rows layout": "Διάταξη σειρών αρχικής",
  "What should this profile get from Main?":
      "Τι να αντιγραφεί από το Κύριο προφίλ;",
  "Copies are independent. Playlists, accounts and device settings stay shared.":
      "Τα αντίγραφα είναι ανεξάρτητα. Λίστες, λογαριασμοί και ρυθμίσεις συσκευής παραμένουν κοινά.",
  "Everything": "Όλα",
  "None": "Κανένα",
  "Save name": "Αποθήκευση ονόματος",
  "Saving…": "Αποθήκευση…",
  "Profile restrictions are fixed when the profile is created.":
      "Οι περιορισμοί ορίζονται κατά τη δημιουργία του προφίλ.",
  "{n} groups allowed": "{n} επιτρεπόμενες ομάδες",
  "{groups} groups hidden · {channels} channels hidden":
      "{groups} κρυφές ομάδες · {channels} κρυφά κανάλια",
  "Main cannot be deleted": "Το Κύριο προφίλ δεν μπορεί να διαγραφεί",
  "Hold OK on a profile to edit it. Hold OK on a season to mark it watched or unwatched.":
      "Κρατήστε OK σε προφίλ για επεξεργασία ή σε σεζόν για σήμανση ως προβληθείσας ή μη.",
  'Coming soon': 'Προσεχώς',
  "Show Cinemeta catalog": "Εμφάνιση καταλόγου Cinemeta",
  "Show the default Popular, New and Featured rows and Cinemeta search results. Turn off to browse only your own catalogs. Posters and episode details may still use Cinemeta.":
      "Εμφάνιση των προεπιλεγμένων σειρών Δημοφιλή, Νέα και Προτεινόμενα και των αποτελεσμάτων αναζήτησης Cinemeta. Απενεργοποιήστε για περιήγηση μόνο στους δικούς σας καταλόγους. Οι αφίσες και οι λεπτομέρειες επεισοδίων ενδέχεται να εξακολουθούν να χρησιμοποιούν το Cinemeta.",
  "Expand": "Ανάπτυξη",
  "Fill the screen with the Timeline guide":
      "Γεμίστε την οθόνη με τον οδηγό προγράμματος",
  "The live channel fills the screen behind a see-through guide":
      "Το ζωντανό κανάλι γεμίζει την οθόνη πίσω από έναν ημιδιαφανή οδηγό",
  "Source: {source}": "Πηγή: {source}",
  "File size: {size}": "Μέγεθος αρχείου: {size}",
  "File size unavailable": "Μη διαθέσιμο μέγεθος αρχείου",

  // Automatic detail trailers.
  "Automatic trailers": "Αυτόματα τρέιλερ",
  "Play available trailers automatically with sound on IPTV and Media Hub movie and show pages.":
      "Αυτόματη αναπαραγωγή με ήχο των διαθέσιμων τρέιλερ στις σελίδες ταινιών και σειρών IPTV και Media Hub.",
  "Trailers": "Τρέιλερ",
  "Play trailers automatically on movie and show pages":
      "Αυτόματη αναπαραγωγή τρέιλερ στις σελίδες ταινιών και σειρών",
  "On Fire TV sticks, the trailer plays full screen.":
      "Στα Fire TV Stick το τρέιλερ παίζει σε πλήρη οθόνη.",
  "Remove \"{title}\" from history?":
      "Να αφαιρεθεί το «{title}» από το ιστορικό;",
  "Import from storage": "Εισαγωγή από αποθηκευτικό μέσο",
  "Add M3U playlists and Media Hub sources from USB or external storage":
      "Προσθήκη λιστών M3U και πηγών Media Hub από USB ή εξωτερικό μέσο",
  "Choose a folder": "Επιλογή φακέλου",
  "Import from storage?": "Εισαγωγή από αποθηκευτικό μέσο;",
  "Import": "Εισαγωγή",
  "Import \"{name}\"? M3U playlists and included Media Hub sources are added without replacing your current setup.":
      "Εισαγωγή του «{name}»; Οι λίστες M3U και οι πηγές Media Hub προστίθενται χωρίς αντικατάσταση της τρέχουσας διαμόρφωσης.",
  "Import M3U playlists and Media Hub source links from USB, SD card or external storage. Choose M3U/M3U8 playlists or TXT/JSON source files.":
      "Εισαγάγετε λίστες M3U και συνδέσμους πηγών Media Hub από USB, κάρτα SD ή εξωτερικό μέσο. Επιλέξτε λίστες M3U/M3U8 ή αρχεία πηγών TXT/JSON.",
  "Could not read this storage location. Use Choose a folder to grant access.":
      "Δεν ήταν δυνατή η ανάγνωση. Χρησιμοποιήστε Επιλογή φακέλου για παραχώρηση πρόσβασης.",
  "No folder picker on this device. Browse the storage devices below instead.":
      "Αυτή η συσκευή δεν διαθέτει επιλογέα φακέλων. Περιηγηθείτε στα παρακάτω αποθηκευτικά μέσα.",
  "No playlists or source files in this folder.":
      "Δεν υπάρχουν λίστες ή αρχεία πηγών σε αυτόν τον φάκελο.",
  "Imported {items} playlist items and {sources} Media Hub sources. {existing} sources already existed; {failed} could not be reached.":
      "Εισήχθησαν {items} στοιχεία λιστών και {sources} πηγές Media Hub. {existing} πηγές υπήρχαν ήδη· δεν ήταν δυνατή η σύνδεση με {failed}.",
  "Could not import this file. Choose an M3U channel playlist or a TXT/JSON file containing Media Hub manifest links.":
      "Δεν ήταν δυνατή η εισαγωγή. Επιλέξτε λίστα καναλιών M3U ή αρχείο TXT/JSON με συνδέσμους manifest του Media Hub.",
  "Hide profiles": "Απόκρυψη προφίλ",
  "Hides the profiles row on Home.":
      "Αποκρύπτει τη σειρά προφίλ στην αρχική σελίδα.",
  "Preferred audio language": "Προτιμώμενη γλώσσα ήχου",
  "Preferred subtitle language": "Προτιμώμενη γλώσσα υποτίτλων",
  "Source default": "Προεπιλογή πηγής",
  "Movies and episodes use these languages when available. Your manual track choices take priority when resuming.":
      "Οι ταινίες και τα επεισόδια χρησιμοποιούν αυτές τις γλώσσες όταν είναι διαθέσιμες. Οι χειροκίνητες επιλογές κομματιών έχουν προτεραιότητα στη συνέχιση.",
  "Playback": "Αναπαραγωγή",
  "Frame rate & resolution": "Ρυθμός καρέ και ανάλυση",
  "Video, audio, subtitles, trailers and player behaviour.":
      "Βίντεο, ήχος, υπότιτλοι, τρέιλερ και συμπεριφορά του προγράμματος αναπαραγωγής.",
  "Theme, tabs, favourites and how the app looks.":
      "Θέμα, καρτέλες, αγαπημένα και εμφάνιση της εφαρμογής.",
  "Audio languages, subtitles and surround sound":
      "Γλώσσες ήχου, υπότιτλοι και ήχος surround",
  "Media Hub playback": "Αναπαραγωγή Media Hub",
  "Default stream selection for movies and episodes":
      "Προεπιλεγμένη επιλογή ροής για ταινίες και επεισόδια",
  "Boxing": "Πυγμαχία",
  "Stream sources": "Πηγές ροής",
  "Up/Down: browse · OK: switch · Back: close":
      "Πάνω/Κάτω: περιήγηση · OK: αλλαγή · Πίσω: κλείσιμο",
  "Could not load stream sources.": "Δεν ήταν δυνατή η φόρτωση των πηγών ροής.",
  "Could not switch stream. Try another source.":
      "Δεν ήταν δυνατή η αλλαγή ροής. Δοκιμάστε άλλη πηγή.",
  "Current stream": "Τρέχουσα ροή",
  "Size unknown": "Άγνωστο μέγεθος",
  "View source URL": "Προβολή URL πηγής",
  "Source URL": "URL πηγής",
  "Copy URL": "Αντιγραφή URL",
  "URL copied": "Το URL αντιγράφηκε",
  "Goals alert": "Ειδοποίηση γκολ",
  "Score alerts for My Teams on any screen":
      "Ειδοποιήσεις σκορ για τις Ομάδες μου σε κάθε οθόνη",
  "Show a top-left popup when a team in My Teams scores. Alerts follow the score feed and pause when scores are hidden.":
      "Εμφάνιση ειδοποίησης πάνω αριστερά όταν σκοράρει ομάδα στις Ομάδες μου. Οι ειδοποιήσεις ακολουθούν τις ενημερώσεις σκορ και παύουν όταν τα σκορ είναι κρυφά.",
  "{team} scored!": "Η ομάδα {team} σκόραρε!",
  "{first} {firstScore} – {secondScore} {second}":
      "{first} {firstScore} – {secondScore} {second}",
  'Catch-up is not available for this channel.':
      'Το catch-up δεν είναι διαθέσιμο για αυτό το κανάλι.',
  'This programme is not available in catch-up.':
      'Αυτή η εκπομπή δεν είναι διαθέσιμη σε catch-up.',
  "Hide Catch-up group": "Απόκρυψη ομάδας Catch-up",
  "Removes the TV tab's Catch-up row (every channel you can replay).":
      "Αφαιρεί τη γραμμή Catch-up από την καρτέλα TV (όλα τα κανάλια με επανάληψη).",
  "No channels with catch-up.": "Κανένα κανάλι με catch-up.",
  "Catch-up playlists": "Λίστες catch-up",
  "Hidden here · {n} channels": "Κρυφή εδώ · {n} κανάλια",
  'Catch-up': 'Catch-up',
  'Previous programme': 'Προηγούμενη εκπομπή',
  'Next programme': 'Επόμενη εκπομπή',
  'Watch from the start': 'Παρακολούθηση από την αρχή',
  '{time} behind live': '{time} πίσω από το ζωντανό',
  'Back to live': 'Επιστροφή στο ζωντανό',
  'Catch-up {time}': 'Catch-up {time}',
  'Now': 'Τώρα',
  "Refined finish": "Εκλεπτυσμένο φινίρισμα",
  "Glossy surfaces, reflections and blur. Uses more graphics resources.":
      "Γυαλιστερές επιφάνειες, αντανακλάσεις και θόλωση. Χρησιμοποιεί περισσότερους πόρους γραφικών.",
  "Video HDR": "HDR βίντεο",
  "Decoder HDR": "HDR αποκωδικοποιητή",
  "Unknown / not reported": "Άγνωστο / δεν αναφέρεται",
  "{format} (stream)": "{format} (ροή)",
  "{format} (decoder)": "{format} (αποκωδικοποιητής)",
  "File size": "Μέγεθος αρχείου",

  // Match-specific score alerts.
  "Remove goals alert for {league}": "Κατάργηση ειδοποιήσεων γκολ για {league}",
  "Goals alert for all of {league}": "Ειδοποιήσεις γκολ για όλη τη {league}",
  "Notify me of every goal in this league (while VesperTV is open). Hide scores pauses alerts.":
      "Ειδοποίησέ με για κάθε γκολ αυτής της λίγκας (όταν το VesperTV είναι ανοιχτό). Η απόκρυψη σκορ θέτει σε παύση τις ειδοποιήσεις.",
  "Watch game button": "Κουμπί Δες τον αγώνα",
  "A reminded game offers Watch game in the player at kickoff":
      "Ένας αγώνας με υπενθύμιση προσφέρει Δες τον αγώνα στο πρόγραμμα αναπαραγωγής στην έναρξη",
  "When a reminded game is about to start, a Watch game button shows in the player for 10 minutes. Press Up from the player bar to reach it, then OK to switch to the game on its best channel. Set a reminder with a hold on the game. {app} must be open. Saved for this viewer.":
      "Όταν ένας αγώνας με υπενθύμιση πρόκειται να ξεκινήσει, ένα κουμπί Δες τον αγώνα εμφανίζεται στο πρόγραμμα αναπαραγωγής για 10 λεπτά. Πατήστε Πάνω από τη γραμμή αναπαραγωγής για να το φτάσετε και OK για να αλλάξετε στον αγώνα στο καλύτερο κανάλι του. Ορίστε υπενθύμιση κρατώντας OK στον αγώνα. Το {app} πρέπει να είναι ανοιχτό. Αποθηκεύεται για αυτό το προφίλ.",
  "Watch game": "Δες τον αγώνα",
  "When the next episode starts by itself":
      "Πότε ξεκινά μόνο του το επόμενο επεισόδιο",
  "Play the next episode": "Αναπαραγωγή επόμενου επεισοδίου",
  "30 seconds before the end": "30 δευτερόλεπτα πριν το τέλος",
  "When the episode ends": "Στο τέλος του επεισοδίου",
  "Never": "Ποτέ",
  "{when}. On TV show episodes, the Up Next card counts down and the next episode starts by itself. Never: no countdown; the episode plays to its end.":
      "{when}. Στα επεισόδια σειρών, η κάρτα Επόμενο μετρά αντίστροφα και το επόμενο επεισόδιο ξεκινά μόνο του. Ποτέ: χωρίς αντίστροφη μέτρηση, το επεισόδιο παίζει ως το τέλος.",
  "Set goals alert for this match":
      "Ενεργοποίηση ειδοποιήσεων γκολ για αυτόν τον αγώνα",
  "Remove goals alert for this match":
      "Κατάργηση ειδοποιήσεων γκολ για αυτόν τον αγώνα",
  "Notify me when either team scores (while VesperTV is open). Hide scores pauses alerts.":
      "Ειδοποίηση όταν σκοράρει οποιαδήποτε ομάδα (όσο το VesperTV είναι ανοιχτό). Η απόκρυψη σκορ αναστέλλει τις ειδοποιήσεις.",
  "Could not save score alert.":
      "Δεν ήταν δυνατή η αποθήκευση της ειδοποίησης σκορ.",
  // Game reminder timing.
  "1 hour before": "1 ώρα πριν",
  "1 day before": "1 ημέρα πριν",
  "1 week before": "1 εβδομάδα πριν",
  "At game time only": "Μόνο στην έναρξη του αγώνα",
  "15 minutes before": "15 λεπτά πριν",
  "Reminder timing": "Χρόνος υπενθύμισης",
  "Advance reminders also notify at game time. VesperTV must be open.":
      "Οι πρόωρες υπενθυμίσεις ειδοποιούν και στην έναρξη του αγώνα. Το VesperTV πρέπει να είναι ανοιχτό.",
  "This reminder time has passed": "Η ώρα αυτής της υπενθύμισης έχει περάσει",
  "Choose when to be reminded (while VesperTV is open)":
      "Επιλέξτε πότε θα ειδοποιηθείτε (όσο το VesperTV είναι ανοιχτό)",
  "Starts in 1 hour": "Ξεκινά σε 1 ώρα",
  "Starts in 1 day": "Ξεκινά σε 1 ημέρα",
  "Starts in 1 week": "Ξεκινά σε 1 εβδομάδα",
  "Schedule": "Πρόγραμμα",
  "Every game of the season, cups included":
      "Όλοι οι αγώνες της σεζόν, μαζί με τα κύπελλα",
  "Could not load the schedule.": "Δεν ήταν δυνατή η φόρτωση του προγράμματος.",
  "OK: stats, watch or game menu · Hold OK: game menu · CH+/CH-: month":
      "OK: στατιστικά, παρακολούθηση ή μενού αγώνα · Κράτημα OK: μενού αγώνα · CH+/CH-: μήνας",
  "No game this day.": "Κανένας αγώνας αυτή την ημέρα.",
  "Next game": "Επόμενος αγώνας",
  "Newest": "Νέες κυκλοφορίες",
  'What happens when a catch-up programme ends':
      "Τι γίνεται όταν τελειώνει ένα πρόγραμμα catch-up",
  'Keep playing after the programme': "Συνέχεια μετά το πρόγραμμα",
  "Off: catch-up pauses when the programme you picked ends, so the next one doesn't start on its own; press Play to carry on. On: it keeps going like the channel did.":
      "Ανενεργό: το catch-up κάνει παύση στο τέλος του προγράμματος που διάλεξες, ώστε το επόμενο να μην ξεκινά μόνο του· πάτα Αναπαραγωγή για συνέχεια. Ενεργό: συνεχίζει όπως το κανάλι.",
  "Channel schedule": "Πρόγραμμα καναλιού",
  "▲ ▼ programmes  ·  OK to watch  ·  Back to close":
      "▲ ▼ εκπομπές  ·  OK για προβολή  ·  Πίσω για κλείσιμο",
  "On now  ·  OK to watch live": "Τώρα  ·  OK για ζωντανή προβολή",
  "Catch-up  ·  OK to watch from the start":
      "Catch-up  ·  OK για προβολή από την αρχή",
  "Upcoming": "Προσεχώς",
  "Show group counts": "Εμφάνιση πλήθους ανά ομάδα",
  "How many channels, movies or shows each group holds, beside its name.":
      "Πόσα κανάλια, ταινίες ή σειρές έχει κάθε ομάδα, δίπλα στο όνομά της.",
  "{m} min back": "{m} λεπτά πίσω",

  // Upcoming TV programmes
  "Starts in 5 minutes": "Ξεκινά σε 5 λεπτά",
  "5 minutes before and at programme time (while VesperTV is open)":
      "5 λεπτά πριν και στην έναρξη της εκπομπής (με το VesperTV ανοιχτό)",
  "Overlaps {title}. Your playlist has no free recording connection.":
      "Συμπίπτει με το {title}. Η λίστα σας δεν έχει ελεύθερη σύνδεση εγγραφής.",
  "Records the programme start to end. Manage it in Recordings.":
      "Εγγράφει την εκπομπή από την αρχή ως το τέλος. Διαχείριση στις Εγγραφές.",
  "Could not schedule recording. Check recording storage and try again.":
      "Δεν ήταν δυνατός ο προγραμματισμός εγγραφής. Ελέγξτε τον αποθηκευτικό χώρο και δοκιμάστε ξανά.",
  "▲ ▼ programmes  ·  OK for options  ·  Back to close":
      "▲ ▼ εκπομπές  ·  OK για επιλογές  ·  Πίσω για κλείσιμο",
  "Upcoming  ·  OK to remind or record":
      "Προσεχώς  ·  OK για υπενθύμιση ή εγγραφή",
  "Recording scheduled. Android may delay the start without exact alarm access.":
      "Η εγγραφή προγραμματίστηκε. Το Android μπορεί να καθυστερήσει την έναρξη χωρίς άδεια ακριβών ειδοποιήσεων.",

  // Plex media-server connector.
  "Connect Jellyfin / Emby / Plex": "Σύνδεση Jellyfin / Emby / Plex",
  "Connect Plex": "Σύνδεση Plex",
  "Sign in on your phone and choose a Plex server":
      "Συνδεθείτε από το τηλέφωνό σας και επιλέξτε διακομιστή Plex",
  "Sign in with Plex on your phone, then choose a server. Your movie and TV libraries appear in the Media Hub. Files play directly, without transcoding.":
      "Συνδεθείτε στο Plex από το τηλέφωνό σας και επιλέξτε διακομιστή. Οι βιβλιοθήκες ταινιών και σειρών εμφανίζονται στο Media Hub. Τα αρχεία αναπαράγονται απευθείας, χωρίς μετατροπή.",
  "Could not connect to Plex. Try again.":
      "Αδυναμία σύνδεσης στο Plex. Δοκιμάστε ξανά.",
  "Plex sign-in expired. Try again.": "Η σύνδεση Plex έληξε. Δοκιμάστε ξανά.",
  "Plex access was denied. Sign in again.":
      "Η πρόσβαση στο Plex απορρίφθηκε. Συνδεθείτε ξανά.",
  "Could not reach this Plex server. Check that it is online and accessible from this device.":
      "Αδυναμία επικοινωνίας με τον διακομιστή Plex. Ελέγξτε ότι είναι συνδεδεμένος και προσβάσιμος από αυτή τη συσκευή.",
  "Choose a Plex server": "Επιλέξτε διακομιστή Plex",
  "No Plex servers are available on this account.":
      "Δεν υπάρχουν διαθέσιμοι διακομιστές Plex σε αυτόν τον λογαριασμό.",
  "Sign in again": "Σύνδεση ξανά",
  "Scan the QR code or visit {url} and enter this code:":
      "Σαρώστε τον κωδικό QR ή επισκεφτείτε το {url} και εισαγάγετε αυτόν τον κωδικό:",

  // Title page row order.
  "Customize title page": "Προσαρμογή σελίδας τίτλου",
  "Choose the order of rows below title details. Saved for this viewer.":
      "Επιλέξτε τη σειρά των γραμμών κάτω από τις λεπτομέρειες του τίτλου. Αποθηκεύεται για αυτό το προφίλ.",

  // My Teams preferred channel.
  "Set preferred channel": "Ορισμός προτιμώμενου καναλιού",
  "Automatic channel": "Αυτόματο κανάλι",
  "Preferred channel for {team}": "Προτιμώμενο κανάλι για {team}",
  "Saved channel is unavailable": "Το αποθηκευμένο κανάλι δεν είναι διαθέσιμο",
  "Hold OK on a team for schedule, preferred channel or unfollow · on a game to pick the channel":
      "Κρατήστε OK σε ομάδα για πρόγραμμα, προτιμώμενο κανάλι ή διακοπή παρακολούθησης · σε αγώνα για επιλογή καναλιού",

  // Sports channel country preferences.
  "Channel preferences and settings for {tab}.":
      "Προτιμήσεις καναλιών και ρυθμίσεις για το {tab}.",
  "Preferred channel countries": "Προτιμώμενες χώρες καναλιών",
  "Prefer local channels while keeping other matches available":
      "Προτεραιότητα στα τοπικά κανάλια με διαθέσιμες και τις άλλες αντιστοιχίσεις",
  "Prefer these countries among channels that match the game. Other countries remain available. Your game and team channel choices still come first.":
      "Δώστε προτεραιότητα σε αυτές τις χώρες μεταξύ των καναλιών που αντιστοιχούν στον αγώνα. Οι άλλες χώρες παραμένουν διαθέσιμες. Οι επιλογές καναλιών για αγώνες και ομάδες έχουν πάντα προτεραιότητα.",
  "Selected countries have equal priority. Match evidence comes before country, then video quality within each group. Saved for this viewer.":
      "Οι επιλεγμένες χώρες έχουν ίση προτεραιότητα. Τα στοιχεία αντιστοίχισης προηγούνται της χώρας και ακολουθεί η ποιότητα βίντεο σε κάθε ομάδα. Αποθηκεύεται για αυτό το προφίλ.",
  "No country preference": "Χωρίς προτίμηση χώρας",
  "Keep the current automatic ranking":
      "Διατήρηση της τρέχουσας αυτόματης κατάταξης",
  "Canada": "Καναδάς",
  "United States": "Ηνωμένες Πολιτείες",
  "United Kingdom": "Ηνωμένο Βασίλειο",
  "Portugal": "Πορτογαλία",
  "Greece": "Ελλάδα",
  "Ireland": "Ιρλανδία",
  "Netherlands": "Ολλανδία",
  "Belgium": "Βέλγιο",
  "Switzerland": "Ελβετία",
  "Austria": "Αυστρία",
  "Denmark": "Δανία",
  "Sweden": "Σουηδία",
  "Norway": "Νορβηγία",
  "Finland": "Φινλανδία",
  "Poland": "Πολωνία",
  "Czechia": "Τσεχία",
  "Slovakia": "Σλοβακία",
  "Hungary": "Ουγγαρία",
  "Romania": "Ρουμανία",
  "Bulgaria": "Βουλγαρία",
  "Croatia": "Κροατία",
  "Serbia": "Σερβία",
  "Slovenia": "Σλοβενία",
  "Bosnia and Herzegovina": "Βοσνία και Ερζεγοβίνη",
  "Albania": "Αλβανία",
  "Türkiye": "Τουρκία",
  "Ukraine": "Ουκρανία",
  "Australia": "Αυστραλία",
  "New Zealand": "Νέα Ζηλανδία",
  "Brazil": "Βραζιλία",
  "Mexico": "Μεξικό",
  "Argentina": "Αργεντινή",
  "Cyprus": "Κύπρος",
  "Estonia": "Εσθονία",
  "Latvia": "Λετονία",
  "Lithuania": "Λιθουανία",
  "Luxembourg": "Λουξεμβούργο",
  "Malta": "Μάλτα",
  "Iceland": "Ισλανδία",
  // Sports preferred playlist.
  "Preferred playlist": "Προτιμώμενη λίστα αναπαραγωγής",
  "Try matching channels from this playlist first":
      "Αναζήτηση αντίστοιχων καναλιών πρώτα σε αυτή τη λίστα",
  "Among comparable game matches, prefer this playlist, then your preferred countries, then video quality. Your game and team channel choices still come first. Other playlists remain available.":
      "Μεταξύ συγκρίσιμων αντιστοιχίσεων αγώνων, προτιμάται αυτή η λίστα, μετά οι προτιμώμενες χώρες και τέλος η ποιότητα βίντεο. Οι επιλογές καναλιών σας για αγώνες και ομάδες παραμένουν πρώτες. Οι άλλες λίστες παραμένουν διαθέσιμες.",
  "Your preferred playlist is unavailable or disabled. Other matching playlists will be used.":
      "Η προτιμώμενη λίστα δεν είναι διαθέσιμη ή είναι απενεργοποιημένη. Θα χρησιμοποιηθούν άλλες λίστες με αντίστοιχα κανάλια.",
  "No playlist preference": "Χωρίς προτίμηση λίστας",
  "Disabled": "Απενεργοποιημένη",
  "No playlists yet": "Δεν υπάρχουν ακόμα λίστες",
  "Selected countries have equal priority. Match evidence comes first, then preferred playlist, country and video quality. Saved for this viewer.":
      "Οι επιλεγμένες χώρες έχουν ίση προτεραιότητα. Προηγείται η αντιστοίχιση αγώνα, μετά η προτιμώμενη λίστα, η χώρα και η ποιότητα βίντεο. Αποθηκεύεται για αυτό το προφίλ.",
  "Rank countries equally": "Ίση προτεραιότητα σε όλες τις χώρες",
  // Hide empty sports leagues.
  "Hide leagues with no games": "Απόκρυψη διοργανώσεων χωρίς αγώνες",
  "Show only leagues with games on the selected day":
      "Εμφάνιση μόνο διοργανώσεων με αγώνες την επιλεγμένη ημέρα",
  "Follows the selected day in Sports Trak. Leagues stay visible while schedules are loading or unavailable. Your saved leagues and their order are kept in Edit leagues. Saved for this viewer.":
      "Ακολουθεί την επιλεγμένη ημέρα στο Sports Trak. Οι διοργανώσεις παραμένουν ορατές κατά τη φόρτωση ή όταν τα προγράμματα δεν είναι διαθέσιμα. Οι αποθηκευμένες διοργανώσεις και η σειρά τους διατηρούνται στην Επεξεργασία διοργανώσεων. Αποθηκεύεται για αυτό το προφίλ.",
  // Updater storage and download checks.
  "Free about {mb} MB and try again.":
      "Ελευθερώστε περίπου {mb} MB και δοκιμάστε ξανά.",
  "Could not check free storage. Restart VesperTV and try again.":
      "Δεν ήταν δυνατός ο έλεγχος του ελεύθερου χώρου. Επανεκκινήστε το VesperTV και δοκιμάστε ξανά.",
  "Could not check the update size. Check for updates and try again.":
      "Δεν ήταν δυνατός ο έλεγχος του μεγέθους της ενημέρωσης. Ελέγξτε για ενημερώσεις και δοκιμάστε ξανά.",
  "Download failed. Please try again.": "Η λήψη απέτυχε. Δοκιμάστε ξανά.",
  // IPTV cast portraits.
  "Metadata provided by TMDB.": "Τα μεταδεδομένα παρέχονται από το TMDB.",
  "No matching title found in your playlists.":
      "Δεν βρέθηκε αντίστοιχος τίτλος στις λίστες αναπαραγωγής σας.",
  "Skip intro": "Παράλειψη εισαγωγής",
  "Skip recap": "Παράλειψη ανακεφαλαίωσης",
  "Skip credits": "Παράλειψη τίτλων τέλους",
  "Skip intro and credits button":
      "Κουμπί παράλειψης εισαγωγής και τίτλων τέλους",
  "Skip intros and credits on TV show episodes":
      "Παράλειψη εισαγωγής και τίτλων τέλους στα επεισόδια",
  "On TV show episodes, a button skips the intro, the recap and the credits (or plays the next episode). Press OK while it shows. Times come from IntroDB (introdb.app), a free community database: it is asked with the show's IMDb id, season and episode number, nothing else.":
      "Στα επεισόδια σειρών, ένα κουμπί παραλείπει την εισαγωγή, την ανακεφαλαίωση και τους τίτλους τέλους (ή παίζει το επόμενο επεισόδιο). Πατήστε OK όσο εμφανίζεται. Οι χρόνοι προέρχονται από το IntroDB (introdb.app), μια δωρεάν κοινοτική βάση: του στέλνεται μόνο το IMDb id της σειράς, η σεζόν και ο αριθμός επεισοδίου.",
  "Betting odds": "Αποδόσεις στοιχημάτων",
  "Show betting odds": "Εμφάνιση αποδόσεων",
  "The line and over/under on game cards, more in the game stats":
      "Η γραμμή και το over/under στις κάρτες αγώνων, περισσότερα στα στατιστικά",
  "Show the line and over/under on games":
      "Εμφάνιση γραμμής και over/under στους αγώνες",
  "Odds come with the scores (one sportsbook, mostly North American leagues) and show before and during a game. Display only: {app} never takes bets or links to a sportsbook. Saved for this viewer.":
      "Οι αποδόσεις έρχονται μαζί με τα σκορ (ένα πρακτορείο, κυρίως λίγκες της Βόρειας Αμερικής) και εμφανίζονται πριν και κατά τη διάρκεια ενός αγώνα. Μόνο προβολή: το {app} δεν δέχεται στοιχήματα ούτε παραπέμπει σε πρακτορείο. Αποθηκεύεται για αυτόν τον θεατή.",
  "Moneyline": "Νικητής",
  "Spread": "Χάντικαπ",
  "Over": "Over",
  "Under": "Under",
  "Draw": "Ισοπαλία",
  "Favourite": "Φαβορί",
  "Total": "Σύνολο",
  "Betting odds · {book}": "Αποδόσεις · {book}",
  "Playlist editor": "Επεξεργασία λίστας",
  "Rename, hide copies, fallbacks and stream test, from your phone or PC": "Μετονομασία, απόκρυψη αντιγράφων, εφεδρικά κανάλια και δοκιμή ροών, από κινητό ή υπολογιστή",
  "Rename, change logos, hide copies and dead streams, set fallback channels and clean up the guide, from your phone or PC. Your provider's playlist is never changed: edits are kept on this device and run again on every content update.": "Μετονομάστε κανάλια, αλλάξτε λογότυπα, κρύψτε αντίγραφα και νεκρές ροές, ορίστε εφεδρικά κανάλια και καθαρίστε τον οδηγό, από κινητό ή υπολογιστή. Η λίστα του παρόχου σας δεν αλλάζει ποτέ: οι αλλαγές μένουν σε αυτή τη συσκευή και εφαρμόζονται ξανά σε κάθε ενημέρωση.",
  "Could not open the editor: {e}": "Δεν ήταν δυνατό το άνοιγμα: {e}",
  "Phone: scan the code.": "Κινητό: σαρώστε τον κωδικό.",
  "PC: open this address in a browser": "Υπολογιστής: ανοίξτε αυτή τη διεύθυνση σε φυλλομετρητή",
  "and enter the code": "και πληκτρολογήστε τον κωδικό",
  "Same Wi-Fi or network as this device. The editor closes when you leave this screen.": "Ίδιο Wi-Fi ή δίκτυο με αυτή τη συσκευή. Ο επεξεργαστής κλείνει όταν φύγετε από αυτή την οθόνη.",
  "Open in browser": "Άνοιγμα στον φυλλομετρητή",
  "Saved from your phone or PC: {name}": "Αποθηκεύτηκε από κινητό ή υπολογιστή: {name}",
  "Stream test {done}/{total}: {name}": "Δοκιμή ροών {done}/{total}: {name}",
  "Stream test: {done}/{total} tested.": "Δοκιμή ροών: {done}/{total} ελέγχθηκαν.",
  "Switch to another copy when a channel fails": "Αλλαγή σε άλλο αντίγραφο όταν ένα κανάλι αποτυγχάνει",
  "If a channel doesn't start or keeps dropping, play its next copy (FHD, then HD…) or your fallback channels, without an error screen.": "Αν ένα κανάλι δεν ξεκινά ή κόβεται συνέχεια, παίζει το επόμενο αντίγραφο (FHD, μετά HD…) ή τα εφεδρικά σας κανάλια, χωρίς οθόνη σφάλματος.",
  "Hide lower-quality copies": "Απόκρυψη αντιγράφων χαμηλότερης ποιότητας",
  "Only the best copy of each channel is listed; the others stay as automatic fallbacks.": "Εμφανίζεται μόνο το καλύτερο αντίγραφο κάθε καναλιού· τα άλλα μένουν ως αυτόματη εφεδρεία.",
  "Hide separator rows": "Απόκρυψη γραμμών διαχωρισμού",
  "Rows like ##### SPORTS #####": "Γραμμές όπως ##### SPORTS #####",
  "{n} channels hidden by the editor": "{n} κανάλια κρυμμένα από τον επεξεργαστή",
  "Rename channel": "Μετονομασία καναλιού",
  "Channel name": "Όνομα καναλιού",
  "Rename…": "Μετονομασία…",
  "Use the provider's name": "Χρήση του ονόματος του παρόχου",
  "Trying another copy: {name}": "Δοκιμή άλλου αντιγράφου: {name}",
  "Previous month": "Προηγούμενος μήνας",
  "Next month": "Επόμενος μήνας",
  "Pause": "Παύση",
  "No guide information": "Χωρίς πληροφορίες οδηγού",
  "Playing {name}": "Αναπαραγωγή: {name}",
  "Up": "Πάνω",
  "Down": "Κάτω",
  "Recently added": "Προστέθηκαν πρόσφατα",
  "Recently added channels": "Κανάλια που προστέθηκαν πρόσφατα",
  "Adds a TV tab group with the channels your playlists added in the last 14 days.": "Προσθέτει μια ομάδα στην καρτέλα TV με τα κανάλια που πρόσθεσαν οι λίστες σας τις τελευταίες 14 ημέρες.",
  "No channels added in the last 14 days.": "Κανένα κανάλι δεν προστέθηκε τις τελευταίες 14 ημέρες.",
  "Live buffer": "Buffer ζωντανής μετάδοσης",
  "Hide short dropouts on live channels": "Κρύβει τις σύντομες διακοπές στα ζωντανά κανάλια",
  "Small (1.5 seconds)": "Μικρό (1,5 δευτερόλεπτο)",
  "Gradual (starts fast, builds up)": "Σταδιακό (ξεκινά γρήγορα, χτίζεται)",
  "building at 96 % speed": "χτίζεται στο 96 % της ταχύτητας",
  "4 seconds": "4 δευτερόλεπτα",
  "8 seconds": "8 δευτερόλεπτα",
  "12 seconds": "12 δευτερόλεπτα",
  "{size}. Live channels store this much before playing, so short dropouts from the server don't show. Bigger hides longer dropouts, but channels start later and play that much behind live. Applies from the next channel.": "{size}. Τα ζωντανά κανάλια αποθηκεύουν τόσο πριν παίξουν, ώστε οι σύντομες διακοπές του διακομιστή να μη φαίνονται. Μεγαλύτερο κρύβει μεγαλύτερες διακοπές, αλλά τα κανάλια ξεκινούν αργότερα και παίζουν τόσο πίσω από το ζωντανό. Ισχύει από το επόμενο κανάλι.",
  "Seasons": "Σεζόν",
  "Playlist editor (Test flight)": "Επεξεργασία λίστας (Test flight)",
  "Add screen": "Προσθήκη οθόνης",
  "Enlarge screen": "Μεγέθυνση οθόνης",
  "Equal screens": "Ίσες οθόνες",
  "Exit full screen": "Έξοδος από πλήρη οθόνη",
  "Remove screen": "Αφαίρεση οθόνης",
  "= audio follows the selected screen · OK for options · hold OK to enlarge": "= ο ήχος ακολουθεί την επιλεγμένη οθόνη · OK για επιλογές · κρατήστε OK για μεγέθυνση",
  "Search and add": "Αναζήτηση και προσθήκη",
  "Hide league names": "Απόκρυψη ονομάτων πρωταθλημάτων",
  "Show league names": "Εμφάνιση ονομάτων πρωταθλημάτων",
  "Check up to 4 live games, then choose Open Multiview": "Επιλέξτε έως 4 ζωντανούς αγώνες και μετά Άνοιγμα Multiview",
  "Only live games can be added": "Μπορούν να προστεθούν μόνο ζωντανοί αγώνες",
  "Multiview shows up to 4 screens": "Το Multiview δείχνει έως 4 οθόνες",
  "Check at least one live game": "Επιλέξτε τουλάχιστον έναν ζωντανό αγώνα",
  "Open Multiview ({n})": "Άνοιγμα Multiview ({n})",
  "Play in Multiview": "Παρακολούθηση σε Multiview",
  "Check other live games to watch together": "Επιλέξτε κι άλλους ζωντανούς αγώνες για να τους δείτε μαζί",
  "{n} sources": "{n} πηγές",
  "Not listed yet": "Δεν έχει καταχωριστεί ακόμη",
  "The newest episode may not be in the catalog yet. Press Play to ask your sources.": "Το νεότερο επεισόδιο ίσως δεν είναι ακόμη στον κατάλογο. Πατήστε Αναπαραγωγή για να ρωτήσετε τις πηγές σας.",
  "The channel stopped. Still trying to reconnect...": "Το κανάλι σταμάτησε. Συνεχίζουμε να προσπαθούμε να επανασυνδεθούμε…",
  "Software video": "Βίντεο λογισμικού",
  "Turn on if channels or movies stay black while the sound or the stream plays. Draws the video without the graphics card path. Uses more CPU on 4K. Applies from the next video.": "Ενεργοποιήστε το αν τα κανάλια ή οι ταινίες μένουν μαύρα ενώ παίζει ο ήχος ή η ροή. Εμφανίζει το βίντεο χωρίς την κάρτα γραφικών. Χρησιμοποιεί περισσότερο τον επεξεργαστή στα 4K. Ισχύει από το επόμενο βίντεο.",
  "For PCs where video stays black": "Για υπολογιστές όπου το βίντεο μένει μαύρο",
};
