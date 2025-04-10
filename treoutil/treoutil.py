from subprocess import check_output
from PyQt6.QtCore import QProcess, Qt
from PyQt6.QtGui import QFont
from PyQt6.QtWidgets import QApplication, QHBoxLayout, QLabel, QPushButton, QScrollArea, QVBoxLayout, QWidget
import sys

app = QApplication(sys.argv)
statusLabel = QLabel("")

processes:list[QProcess] = []

init_message = "F-klubben - #FRITFIT\n" + ("\n".join(check_output([sys.argv[1], "-f", "slant", "TREO"]).decode().split("\n")[:-2]) + " UTIL\n\nTREOens Utility program\n")

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
stdout_label.setFont(QFont("Monospace", 12))
stderr_label = ScrollLabel()
stderr_label.setFont(QFont("Monospace", 12))

def finishedUpdate():
    print("Update finished!")
    statusLabel.setText("Update finished!")
    p = processes.pop()
    print(p.exitStatus().value)

def update():
    print("Updating Strandvejen...")
    statusLabel.setText("Updating Strandvejen...")
    p = QProcess()
    stderr_label.append(init_message)
    p.start(sys.argv[0].replace("treoutil.py", "update.sh"))
    p.readyRead.connect(lambda: stdout_label.append(p.readAllStandardOutput().data().decode()))
    p.readyReadStandardError.connect(lambda: stderr_label.append(p.readAllStandardError().data().decode()))
    p.finished.connect(finishedUpdate)
    processes.append(p)

def restart():
    print("Restarting system...")
    statusLabel.setText("Restarting system...")
    p = QProcess()
    p.start("reboot")
    processes.append(p)

def restartStrandvejen():
    print("Restarting Strandvejen...")
    statusLabel.setText("Restarting Strandvejen...")
    p = QProcess()
    p.start(sys.argv[0].replace("treoutil.py", "restart-strandvejen.sh"))
    p.readyRead.connect(lambda: stdout_label.append(p.readAllStandardOutput().data().decode()))
    p.readyReadStandardError.connect(lambda: stderr_label.append(p.readAllStandardError().data().decode()))
    p.finished.connect(finishedUpdate)
    processes.append(p)

print(init_message)

widget:QWidget = QWidget()
widget.setWindowTitle("TREO UTIL")
firstLayout = QVBoxLayout()
firstLayout.addWidget(QLabel("TREOens Utility program"))
firstLayout.setAlignment(Qt.AlignmentFlag.AlignTop)
secondLayout = QHBoxLayout()
secondLayout.addWidget(QLabel("Choose a task:"))
updateButton = QPushButton("Update Strandvejen")
restartButton = QPushButton("Restart system")
closeButton = QPushButton("Close TREO UTIL")
restartStrandvejenButton = QPushButton("Restart Strandvejen")
updateButton.clicked.connect(update)
restartButton.clicked.connect(restart)
closeButton.clicked.connect(app.quit)
restartStrandvejenButton.clicked.connect(restartStrandvejen)
secondLayout.addWidget(updateButton)
secondLayout.addWidget(restartButton)
secondLayout.addWidget(restartStrandvejenButton)
secondLayout.addWidget(closeButton)
firstLayout.addLayout(secondLayout)
firstLayout.addWidget(statusLabel)
thirdLayout = QHBoxLayout()
showOutputButton = QPushButton("Show output log")
showOutputButton.clicked.connect(lambda: stdout_label.show() if stdout_label.isHidden() else stdout_label.hide())
showErrorButton = QPushButton("Show error log")
showErrorButton.clicked.connect(lambda: stderr_label.show() if stderr_label.isHidden() else stderr_label.hide())
thirdLayout.addWidget(showOutputButton)
thirdLayout.addWidget(showErrorButton)
firstLayout.addLayout(thirdLayout)
fourthLayout = QVBoxLayout()
fourthLayout.addWidget(stdout_label)
fourthLayout.addWidget(stderr_label)
stdout_label.hide()
#stderr_label.hide()
firstLayout.addLayout(fourthLayout)
widget.setLayout(firstLayout)
widget.setMinimumSize(200, 600)
widget.show()

exit(app.exec())

