#!/usr/bin/env Rscript

# =========================================================
# make_video.R
#
# Create an MP4 video from sequential PNG map images
# using ffmpeg.
#
# Usage:
#   Rscript make_video.R <image_folder> <pattern_piece> <output_video> [fps]
#
# Example:
#   Rscript make_video.R \
#   "/home/usuario/Escritorio/phygeo-v0.4.0.linux-amd64/Osmunda crown" \
#   "-n12-" \
#   "Osmunda_n12.mp4" \
#   2
#
# =========================================================

# --- Read command-line arguments ---
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {

  cat("\nUsage:\n")
  cat("  Rscript make_video.R <image_folder> <pattern_piece> <output_video> [fps]\n\n")

  cat("Example:\n")
  cat("  Rscript make_video.R ")
  cat("'/home/user/maps' '-n12-' 'Osmunda.mp4' 2\n\n")

  quit(status = 1)
}

# --- Input arguments ---
img_dir <- args[1]
pattern_piece <- args[2]
output_video <- args[3]

# Optional FPS argument
fps <- ifelse(length(args) >= 4, as.numeric(args[4]), 2)

# =========================================================
# Find matching PNG files
# =========================================================

pattern <- sprintf("^MAP-leptopteroid_tree%s.*\\.png$", pattern_piece)

imgs <- list.files(
  img_dir,
  pattern = pattern,
  full.names = TRUE
)

# --- Check that files exist ---
if (length(imgs) == 0) {

  stop(
    paste0(
      "\n❌ No matching images found.\n",
      "Folder: ", img_dir, "\n",
      "Pattern: ", pattern, "\n"
    )
  )
}

# =========================================================
# Sort numerically by the LAST number in filename
# and reverse order (past → present)
# =========================================================

time_values <- as.numeric(
  gsub(".*-(\\d+\\.\\d+)\\.png", "\\1", imgs)
)

imgs <- imgs[order(time_values, decreasing = TRUE)]

# =========================================================
# Create temporary directory with sequential filenames
# =========================================================

tmp_dir <- file.path(img_dir, "tmp_frames")

dir.create(tmp_dir, showWarnings = FALSE)

# Copy images with ffmpeg-friendly names
for (i in seq_along(imgs)) {

  new_name <- sprintf(
    "%s/frame_%04d.png",
    tmp_dir,
    i
  )

  file.copy(imgs[i], new_name, overwrite = TRUE)
}

# =========================================================
# Build ffmpeg command
# =========================================================

cmd <- sprintf(
  paste(
    "ffmpeg -y",
    "-framerate %d",
    "-i '%s/frame_%%04d.png'",
    "-c:v libx264",
    "-pix_fmt yuv420p",
    "'%s'"
  ),
  fps,
  tmp_dir,
  output_video
)

# =========================================================
# Run ffmpeg
# =========================================================

cat("\n🎬 Creating video...\n\n")

system(cmd)

cat("\n✅ Video saved as:", output_video, "\n")

# =========================================================
# Cleanup temporary files
# =========================================================

unlink(tmp_dir, recursive = TRUE)

cat("🧹 Temporary files removed.\n\n")