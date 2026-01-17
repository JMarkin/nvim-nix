set -x
nix flake archive --json |
	jq -r '.path,(.inputs|to_entries[].value.path)' |
	cachix push jmarkin
for target in $(
	nix flake show --json --all-systems | jq '
	.["packages"] | 
	to_entries[] | 
	select(.key | . != "aarch64-darwin" and . != "x86_64-darwin") | 
	.key as $arch | 
	.value | 
	keys[] | 
	"packages.\($arch).\(.)"
	' | tr -d '"'
); do
	nix build --json ".#$target" |
	jq -r '.[].outputs | to_entries[].value' |
	cachix push jmarkin
done
