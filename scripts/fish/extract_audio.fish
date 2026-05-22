#!/usr/bin/env fish

set input_dir video
set output_dir audio

# Check ffmpeg exists
if not type -q ffmpeg
    echo "Error: ffmpeg is not installed or not in PATH." >&2
    exit 1
end

# Check input directory exists
if not test -d "$input_dir"
    echo "Error: input directory '$input_dir' does not exist." >&2
    exit 1
end

# Create output directory if missing
if not test -d "$output_dir"
    echo "Creating output directory '$output_dir'..."
    mkdir -p "$output_dir"
    or begin
        echo "Error: failed to create output directory '$output_dir'." >&2
        exit 1
    end
end

# Collect matching files
set files "$input_dir"/bigdata_*.mp4

# Fish leaves unmatched globs literal unless checked with test
if test (count $files) -eq 0; or not test -e $files[1]
    echo "No files found matching '$input_dir/bigdata_*.mp4'."
    exit 0
end

set converted 0
set skipped 0
set failed 0

for input_file in $files
    # Skip anything that is not a regular file
    if not test -f "$input_file"
        echo "Skipping non-file: $input_file"
        set skipped (math $skipped + 1)
        continue
    end

    set base (basename "$input_file" .mp4)
    set output_file "$output_dir/$base.wav"

    # Skip if output already exists
    if test -e "$output_file"
        echo "Skipping existing file: $output_file"
        set skipped (math $skipped + 1)
        continue
    end

    echo "Converting: $input_file -> $output_file"

    ffmpeg \
        -hide_banner \
        -loglevel error \
        -i "$input_file" \
        -vn \
        -ac 1 \
        -ar 16000 \
        -c:a pcm_s16le \
        "$output_file"

    if test $status -eq 0
        set converted (math $converted + 1)
    else
        echo "Error: failed to convert '$input_file'." >&2
        rm -f "$output_file"
        set failed (math $failed + 1)
    end
end

echo
echo "Done."
echo "Converted: $converted"
echo "Skipped:   $skipped"
echo "Failed:    $failed"

if test $failed -gt 0
    exit 1
end