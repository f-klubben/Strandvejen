from subprocess import check_output
from PyQt6.QtCore import QProcess, Qt
from PyQt6.QtWidgets import QApplication, QHBoxLayout, QLabel, QPushButton, QScrollArea, QVBoxLayout, QWidget
import sys

app = QApplication(sys.argv)
statusLabel = QLabel("")

processes:list[QProcess] = []

class ScrollLabel(QScrollArea):

    # constructor
    def __init__(self, *args, **kwargs):
        QScrollArea.__init__(self, *args, **kwargs)

        # making widget resizable
        self.setWidgetResizable(True)

        # making qwidget object
        content = QWidget(self)
        self.setWidget(content)

        # vertical box layout
        lay = QVBoxLayout(content)

        # creating label
        self.label = QLabel(content)

        # setting alignment to the text
        self.label.setAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignTop)

        # making label multi-line
        self.label.setWordWrap(True)

        # adding label to the layout
        lay.addWidget(self.label)

    # the setText method
    def setText(self, text):
        # setting text to the label
        self.label.setText(text)
        vbar = self.verticalScrollBar()
        vbar.setValue(vbar.maximum())

    def append(self, text):
        self.label.setText(self.label.text() + text)
        vbar = self.verticalScrollBar()
        vbar.setValue(vbar.maximum())

stdout_label = ScrollLabel()
stderr_label = ScrollLabel()

def finishedUpdate():
    print("Opdatering færdig!")
    statusLabel.setText("Opdatering færdig!")
    p = processes.pop()
    print(p.exitStatus().value)

def update():
    print("Opdaterer stregmaskinen...")
    statusLabel.setText("Opdaterer stregmaskinen...")
    p = QProcess()
    p.start(sys.argv[0].replace("treoutil.py", "update.sh"))
    p.readyRead.connect(lambda: stdout_label.append(p.readAllStandardOutput().data().decode()))
    p.readyReadStandardError.connect(lambda: stderr_label.append(p.readAllStandardError().data().decode()))
    p.finished.connect(finishedUpdate)
    processes.append(p)

def restart():
    print("Genstarter stregmaskinen...")
    statusLabel.setText("Genstarter stregmaskinen...")
    p = QProcess()
    p.start("reboot")
    processes.append(p)

print("F-klubben - #FRITFIT")
print("\n".join(check_output([sys.argv[1], "-f", "slant", "TREO"]).decode().split("\n")[:-2]) + " UTIL\n\nTREOens Opdateringsværktøj")

widget = QWidget()
widget.setWindowTitle("TREO UTIL")
firstLayout = QVBoxLayout()
firstLayout.addWidget(QLabel("TREOens Opdateringsværktøj"))
firstLayout.setAlignment(Qt.AlignmentFlag.AlignTop)
secondLayout = QHBoxLayout()
secondLayout.addWidget(QLabel("Vælg en opgave:"))
updateButton = QPushButton("Opdater stregmaskinen")
restartButton = QPushButton("Genstart stregmaskinen")
closeButton = QPushButton("Luk TREO UTIL")
updateButton.clicked.connect(update)
restartButton.clicked.connect(restart)
closeButton.clicked.connect(app.quit)
secondLayout.addWidget(updateButton)
secondLayout.addWidget(restartButton)
secondLayout.addWidget(closeButton)
firstLayout.addLayout(secondLayout)
firstLayout.addWidget(statusLabel)
thirdLayout = QHBoxLayout()
showOutputButton = QPushButton("Vis output log")
showOutputButton.clicked.connect(lambda: stdout_label.show() if stdout_label.isHidden() else stdout_label.hide())
showErrorButton = QPushButton("Vis error log")
showErrorButton.clicked.connect(lambda: stderr_label.show() if stderr_label.isHidden() else stderr_label.hide())
thirdLayout.addWidget(showOutputButton)
thirdLayout.addWidget(showErrorButton)
firstLayout.addLayout(thirdLayout)
fourthLayout = QVBoxLayout()
fourthLayout.addWidget(stdout_label)
fourthLayout.addWidget(stderr_label)
stdout_label.hide()
stderr_label.hide()
firstLayout.addLayout(fourthLayout)
widget.setLayout(firstLayout)
widget.show()

exit(app.exec())

