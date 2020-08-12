function Controller() {}
Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
    print("IntroPage\n");
}
Controller.prototype.TargetDirectoryPageCallback = function() {
    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    page.TargetDirectoryLineEdit.setText("c:\\msys64");
    gui.clickButton(buttons.NextButton);
    print("TargetDir\n");
}
Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
    print("StartMenu\n");
}
Controller.prototype.FinishedPageCallback = function() {
    gui.clickButton(buttons.FinishButton);
    print("Finish\n");
}
