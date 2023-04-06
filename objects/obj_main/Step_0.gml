if (!EmuOverlay.GetTop()) {
    if (keyboard_check(vk_control)) {
        if (keyboard_check_pressed(ord("S"))) {
            self.ShowSaveDialog();
        }
        else if (keyboard_check_pressed(ord("O"))) {
            self.ShowLoadDialog();
        }
        else if (keyboard_check_pressed(ord("I"))) {
            self.ShowImportImageDialog();
        }
    }
}