# from md table -> sql -> sel all -> copy data as pretty
# https://tableconvert.com/markdown-to-sql

USE ian_test_db;

# <editor-fold defaultstate="collapsed or open" desc="nerdtree_shortcuts" >

CREATE TABLE `nerdtree` (
    `Key`         VARCHAR(512),
    `Description` VARCHAR(512),
    `Map Setting` VARCHAR(512)
);

INSERT INTO `nerdtree` (`Key`, `Description`, `Map Setting`)
VALUES ('o', 'Open files, directories and bookmarks', 'g:NERDTreeMapActivateNode'),
       ('go', 'Open selected file, but leave cursor in the NERDTree', 'g:NERDTreeMapPreview'),
       ('t', 'Open selected node/bookmark in a new tab', 'g:NERDTreeMapOpenInTab'),
       ('T', 'Same as \'t\' but keep the focus on the current tab', 'g:NERDTreeMapOpenInTabSilent'),
       ('i', 'Open selected file in a split window', 'g:NERDTreeMapOpenSplit'),
       ('gi', 'Same as i, but leave the cursor on the NERDTree', 'g:NERDTreeMapPreviewSplit'),
       ('s', 'Open selected file in a new vsplit', 'g:NERDTreeMapOpenVSplit'),
       ('gs', 'Same as s, but leave the cursor on the NERDTree', 'g:NERDTreeMapPreviewVSplit'),
       ('O', 'Recursively open the selected directory', 'g:NERDTreeMapOpenRecursively'),
       ('x', 'Close the current nodes parent', 'g:NERDTreeMapCloseDir'),
       ('X', 'Recursively close all children of the current node', 'g:NERDTreeMapCloseChildren'),
       ('P', 'Jump to the root node', 'g:NERDTreeMapJumpRoot'),
       ('p', 'Jump to current nodes parent', 'g:NERDTreeMapJumpParent'),
       ('K', 'Jump up inside directories at the current tree depth', 'g:NERDTreeMapJumpFirstChild'),
       ('J', 'Jump down inside directories at the current tree depth', 'g:NERDTreeMapJumpLastChild'),
       ('<C-J>', 'Jump down to next sibling of the current directory', 'g:NERDTreeMapJumpNextSibling'),
       ('<C-K>', 'Jump up to previous sibling of the current directory', 'g:NERDTreeMapJumpPrevSibling'),
       ('r', 'Recursively refresh the current directory', 'g:NERDTreeMapRefresh'),
       ('R', 'Recursively refresh the current root', 'g:NERDTreeMapRefreshRoot'),
       ('m', 'Display the NERDTree menu', 'g:NERDTreeMapMenu'),
       ('q', 'Close the NERDTree window', 'g:NERDTreeMapQuit'),
       ('A', 'Zoom (maximize/minimize) the NERDTree window', 'g:NERDTreeMapToggleZoom');

SELECT *
FROM nerdtree;

DROP TABLE nerdtree;
# </editor-fold>