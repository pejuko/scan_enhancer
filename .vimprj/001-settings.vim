" Indexer Configuration
let g:indexer_projectsSettingsFilename = $INDEXER_PROJECT_ROOT.'/.vimprj/project'


" TagList Configuration
let Tlist_Use_Right_Window = 1
let Tlist_Use_SingleClick = 1
let Tlist_Compact_Format = 1
let Tlist_Display_Prototype = 1
let Tlist_GainFocus_On_ToggleOpen = 0
"let Tlist_Use_Horiz_Window = 1

nnoremap <silent> <F8> :TlistToggle<CR>
