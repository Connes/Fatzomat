# Branding & Launch Screen – V59

## Ziel
Das freigegebene "together"-Logo aus dem Referenzbild wird als App-Icon und als Startmarke verwendet.

## Assets
- `assets/branding/app_icon.png` – 1024×1024, aus dem Referenzbild extrahiert.
- `assets/branding/launch_heart.png` – extrahierte Herz-/Besteckmarke für die Launch-Seite.
- `assets/branding/launch_vegetables.png` – extrahierter Gemüsebereich der Launch-Seite.
- `assets/branding/launch_screen_reference.png` – unbearbeitete Referenz des dargestellten Launch-Screens.

## App-Start
`LaunchPage` zeigt ca. 1,8 Sekunden die neue together-Marke und wechselt anschließend per Fade auf den bestehenden Startup-/Onboarding-Flow.

Die System-Statusleiste bleibt echt und wird nicht als Screenshot nachgebaut. Dadurch bleibt die Launch-Seite auf Android und iOS sauber skalierbar.

## Launcher-Icon
Das fertige Master-Icon liegt unter `assets/branding/app_icon.png`.

Da dieses Projekt keine nativen `android/`- und `ios/`-Ordner im Release-ZIP enthält, wird das Master-Icon bewusst nicht in native Plattformdateien geschrieben. Beim lokalen Projekt kann es mit dem vorhandenen Flutter-Launcher-Icon-Workflow in Android/iOS-Launcher-Assets übernommen werden.
