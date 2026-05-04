appdir <- tempfile("shinylive-app-")
dir.create(appdir)

file.copy("app.R", file.path(appdir, "app.R"), overwrite = TRUE)

if (dir.exists("www")) {
  file.copy("www", appdir, recursive = TRUE)
}

shinylive::export(appdir = appdir, destdir = "docs")
