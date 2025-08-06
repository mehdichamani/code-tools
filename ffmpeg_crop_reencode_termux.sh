#!/data/data/com.termux/files/usr/bin/bash
# Batch process MP4 files with ffmpeg in Termux (Android)
# Compatible with ffmpeg v7.1.1

# Define available filters
filters=(
  'crop=1080:1080:700:0' # Crop1 (ED)
  'crop=1080:1080:0:0'   # Crop2 (AB)
  'eq=brightness=0.1:contrast=1.3:saturation=1.2:gamma=1.1' # Light Fix
  'hqdn3d=1.5:1.5:6:6'   # Digital Noise Fix
  'unsharp=7:7:1.5:7:7:0.0' # Strong Sharp & Noise
  'smartblur=1.5:-0.35:-3.5:0.65:0.25:2.0' # Soft Sharp & Noise
)

filter_names=(
  'Crop1 (ED)'
  'Crop2 (AB)'
  'Light Fix'
  'Digital Noise Fix'
  'Strong Sharp & Noise'
  'Soft Sharp & Noise'
)

# Set input directory to current directory if available, otherwise use downloads
if [ -n "$PWD" ] && [ "$PWD" != "$HOME" ]; then
  input_dir="$PWD"
else
  input_dir=~/storage/downloads
fi
echo "Using input directory: $input_dir"

output_dir="$input_dir/output"
mkdir -p "$output_dir"

# Show filter options
echo "Available filters:"
for i in "${!filter_names[@]}"; do
  printf "[%d] %s : %s\n" $((i+1)) "${filter_names[$i]}" "${filters[$i]}"
done

read -p "Enter filter numbers to apply, separated by commas (e.g. 1,3,4): " selection
IFS=',' read -ra selected <<< "$selection"
selected_indexes=()
for idx in "${selected[@]}"; do
  idx=$(echo "$idx" | xargs) # trim
  if [[ "$idx" =~ ^[1-9][0-9]*$ ]] && [ "$idx" -le ${#filters[@]} ]; then
    selected_indexes+=( $((idx-1)) )
  fi
done

if [ ${#selected_indexes[@]} -eq 0 ]; then
  echo "No valid filters selected. Exiting."
  exit 1
fi

# Combine selected filters
selected_filters=""
for i in "${selected_indexes[@]}"; do
  if [ -z "$selected_filters" ]; then
    selected_filters="${filters[$i]}"
  else
    selected_filters+="","${filters[$i]}"
  fi
done

# Create filter numbers string like (1,2,3)
filter_numbers="("$(IFS=','; echo "${selected[@]}")")"

# Ask for encoder preference
read -p "Use CPU encoding instead of GPU? (slower but better quality) [y/N]: " use_cpu
use_cpu=${use_cpu,,} # convert to lowercase

# Process MP4 files
shopt -s nullglob
files=("$input_dir"/*.mp4)
if [ ${#files[@]} -eq 0 ]; then
  echo "No MP4 files found in $input_dir"
  exit 1
fi

for file in "${files[@]}"; do
  base=$(basename "$file" .mp4)
  output_file="$output_dir/${base}_new${filter_numbers}.mp4"
  if [[ "$use_cpu" == "y" || "$use_cpu" == "yes" ]]; then
    ffmpeg -i "$file" -vf "$selected_filters" -c:v libx264 -crf 23 -preset medium -c:a copy "$output_file"
  else
    ffmpeg -hwaccel mediacodec -i "$file" -vf "$selected_filters" -c:v h264_mediacodec -c:a copy "$output_file"
  fi
  if [ $? -ne 0 ]; then
    echo "Error processing $file"
    exit 1
  fi
  echo "Processed: $file -> $output_file"
done

echo "Completed!"
