if exists('g:did_load_tests_plugin')
  finish
endif

let g:did_load_tests_plugin = v:true

let g:test#prompt_for_unsaved_changes = 1


nmap <silent> <leader>Tt :TestNearest<CR>
nmap <silent> <leader>TT :TestFile<CR>
nmap <silent> <leader>Ta :TestSuite<CR>
nmap <silent> <leader>Tl :TestLast<CR>
nmap <silent> <leader>Tg :TestVisit<CR>


let test#strategy = "neovim"

let test#python#runner = 'pytest'
" Runners available are 'pytest', 'nose', 'nose2', 'djangotest', 'djangonose', 'mamba', and Python's built-in unittest as 'pyunit'


let test#go#runner = 'gotest'
" Runners available are 'gotest', 'ginkgo', 'richgo', 'delve'



