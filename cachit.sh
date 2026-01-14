set -x
nix flake archive --json |
	jq -r '.path,(.inputs|to_entries[].value.path)' |
	cachix push jmarkin
for target in $(
	nix flake show --json --all-systems | jq '
	.["packages"] | 
	to_entries[] | 
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
