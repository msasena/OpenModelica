######################################################################
# Automatically generated by qmake (1.07a) Mon Nov 15 16:21:23 2004
######################################################################
# Adrian Pop [adrpo@ida.liu.se] 2008-10-02
#  - make sure that mico-config, coin-config, soqt-config are in the $PATH!

TEMPLATE = app
INCLUDEPATH += . \
               /usr/local/include
#OBJECTS +=

win32 {
  CORBAINC = $$system(mico-config --prefix)/include
  CORBALIBS = $$system(mico-config --libs)
  DEFINES += HAVE_MICO
  COIN_INCLUDE = $$system(coin-config --includedir)
  SOQT_INCLUDE = $$system(soqt-config --includedir)
  COIN_LIBS = $$system(coin-config --ldflags --libs)
  SOQT_LIBS = $$system(soqt-config --ldflags --libs)
} else {
  include(OMNotebook.config)
}

LIBS += -L${ANTLRHOME}/lib -lantlr $${CORBALIBS} $${COIN_LIBS} $${SOQT_LIBS}
INCLUDEPATH += $${CORBAINC} \
               $${COIN_INCLUDE} \
               $${SOQT_INCLUDE} \
               /usr/include/qt4/ \
               ${ANTLRHOME}/include \
               ../NotebookParser \
               ../Pltpkg2 \
               ../3Dpkg

TARGET = OMNotebook

## For debugging
QMAKE_CFLAGS+=
QMAKE_CXXFLAGS+=
QMAKE_LFLAGS+=

#If omc is installed on system. Set includepath and objects
#correctly. If omc not is installed on the system. Comment out
#theese three lines below.
DEFINES += OMC $${HAVE_COIN} $${USE_CORBA}

QT += network xml core gui opengl

# Input
HEADERS += ../NotebookParser/AntlrNotebookLexer.hpp\
           ../NotebookParser/AntlrNotebookParser.hpp\
           ../NotebookParser/AntlrNotebookTreeParser.hpp\
           omc_communicator.hpp \
           omc_communication.h \
           application.h \
           command.h \
           notebookparser.h \
           serializingvisitor.h \
           cellapplication.h \
           commandunit.h \
           notebooksocket.h \
           stripstring.h \
           cellcommandcenter.h \
           cursorcommands.h \
           omcinteractiveenvironment.h\
           stylesheet.h \
           cellcommands.h \
           cursorposvisitor.h \
           openmodelicahighlighter.h \
           syntaxhighlighter.h \
           cellcursor.h \
           document.h \
           otherdlg.h \
           textcell.h \
           celldocument.h \
           documentview.h \
           parserfactory.h \
           textcursorcommands.h \
           celldocumentview.h \
           factory.h \
           printervisitor.h\
           treeview.h \
           cellfactory.h \
           highlighterthread.h \
           puretextvisitor.h \
           updategroupcellvisitor.h \
           cellgroup.h \
           imagesizedlg.h \
           qcombobox_search.h \
           updatelinkvisitor.h \
           cell.h \
           inputcelldelegate.h \
           removehighlightervisitor.h \
           visitor.h \
           cellstyle.h \
           inputcell.h \
           replaceallvisitor.h \
           xmlnodename.h \
           chaptercountervisitor.h \
           nbparser.h \
           resource1.h \
           xmlparser.h \
           commandcenter.h \
           notebookcommands.h \
           rule.h \
           commandcompletion.h \
           notebook.h \
           searchform.h \
           graphcell.h \
           evalthread.h \
           indent.h \
	   ../Pltpkg2/legendLabel.h \
	   ../Pltpkg2/compoundWidget.h \
	   ../Pltpkg2/dataSelect.h \
           ../Pltpkg2/graphWindow.h \
           ../Pltpkg2/curve.h \
	   ../Pltpkg2/point.h \
	   ../Pltpkg2/label.h \
	   ../Pltpkg2/focusRect.h \
	   ../Pltpkg2/graphScene.h \
	   ../Pltpkg2/graphWidget.h \
	   ../Pltpkg2/line2D.h \
	   ../Pltpkg2/lineGroup.h \
	   ../Pltpkg2/preferenceWindow.h \
	   ../Pltpkg2/variableData.h \
	   ../Pltpkg2/verticalLabel.h \
           ../Pltpkg2/variablewindow.h \
           ../3Dpkg/SimulationData.h \
           ../3Dpkg/VisualizationWidget.h

SOURCES += ../NotebookParser/AntlrNotebookLexer.cpp\
           ../NotebookParser/AntlrNotebookParser.cpp\
           ../NotebookParser/AntlrNotebookTreeParser.cpp\
           cellapplication.cpp \
           cellparserfactory.cpp \
           omc_communicator.cpp \
           omc_communication.cc \
           stylesheet.cpp \
           cellcommandcenter.cpp \
           chaptercountervisitor.cpp \
           omcinteractiveenvironment.cpp \
           textcell.cpp \
           cellcommands.cpp \
           commandcompletion.cpp \
           openmodelicahighlighter.cpp \
           textcursorcommands.cpp \
           cell.cpp \
           printervisitor.cpp \
           treeview.cpp \
           cellcursor.cpp \
           highlighterthread.cpp \
           puretextvisitor.cpp \
           updategroupcellvisitor.cpp \
           celldocument.cpp \
           inputcell.cpp  \
           qcombobox_search.cpp \
           updatelinkvisitor.cpp \
           cellfactory.cpp \
           notebook.cpp \
           qtapp.cpp \
           xmlparser.cpp \
           notebookparser.cpp \
           searchform.cpp \
           cellgroup.cpp \
           notebooksocket.cpp \
           serializingvisitor.cpp \
           graphcell.cpp \
           evalthread.cpp \
           indent.cpp \
	   ../Pltpkg2/compoundWidget.cpp \
	   ../Pltpkg2/dataSelect.cpp \
           ../Pltpkg2/graphWindow.cpp \
           ../Pltpkg2/curve.cpp \
	   ../Pltpkg2/point.cpp \
	   ../Pltpkg2/legendLabel.cpp \
	   ../Pltpkg2/graphWidget.cpp \
	   ../Pltpkg2/line2D.cpp \
	   ../Pltpkg2/lineGroup.cpp \
	   ../Pltpkg2/preferenceWindow.cpp \
	   ../Pltpkg2/variableData.cpp \
           ../Pltpkg2/variablewindow.cpp \
           ../3Dpkg/SimulationData.cpp \
           ../3Dpkg/VisualizationWidget.cpp

FORMS += ImageSizeDlg.ui \
         OtherDlg.ui \
         searchform.ui \
         ../Pltpkg2/compoundWidget.ui\
         ../Pltpkg2/dataSelect.ui\
         ../Pltpkg2/graphWindow.ui\
         ../Pltpkg2/preferences.ui \
         ../Pltpkg2/newgraph.ui

RESOURCES += res_qt.qrc

CONFIG += warn_off
