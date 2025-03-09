import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import '../util/localization.dart';
import '../methods/copy_files.dart';

class DragDropPage extends StatefulWidget {
  const DragDropPage({super.key});

  @override
  DragDropPageState createState() => DragDropPageState();
}

class DragDropPageState extends State<DragDropPage> {
  String sourcePath = '';
  String destinationPath = '';
  bool _isDraggingSource = false;
  bool _isDraggingDestination = false;

  int totalFiles = 0;
  int processedFiles = 0;

  Future<void> _updateFileCount(String path) async {
    final count = await countFiles(path);
    setState(() {
      totalFiles = count;
      processedFiles = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getLocalizedString(context, 'appTitle')),
      ),
      body: mainPage(context),
    );
  }

  Padding mainPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: dropZone(context),
          ),
          SizedBox(height: 24),
          srcPath(context),
          SizedBox(height: 16),
          dstPath(context),
          SizedBox(height: 16),
          fileCopyArea(context),
        ],
      ),
    );
  }

  Row fileCopyArea(BuildContext context) {
    return Row(
      children: [
        fileCopyProgress(),
        const SizedBox(width: 8),
        fileCopyButton(context),
      ],
    );
  }

  ElevatedButton fileCopyButton(BuildContext context) {
    return ElevatedButton(
      onPressed: (sourcePath.isNotEmpty && destinationPath.isNotEmpty)
          ? () {
              setState(() {
                processedFiles = 0;
              });
              copyFiles(
                sourcePath: sourcePath,
                destinationPath: destinationPath,
                context: context,
                getLocalizedString: getLocalizedString,
                progressCallback: (int processed, int total) {
                  setState(() {
                    processedFiles = processed;
                  });
                },
              );
            }
          : null,
      child: Text(getLocalizedString(context, 'copyButton')),
    );
  }

  Expanded fileCopyProgress() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          LinearProgressIndicator(
            minHeight: 20,
            value: totalFiles > 0 ? processedFiles / totalFiles : 0,
          ),
          Text(
            totalFiles > 0
                ? '${((processedFiles / totalFiles) * 100).toStringAsFixed(0)}% ($processedFiles/$totalFiles)'
                : '0%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TextField dstPath(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: destinationPath),
      readOnly: true,
      decoration: InputDecoration(
        labelText: getLocalizedString(context, 'destinationPath'),
        border: OutlineInputBorder(),
      ),
    );
  }

  Row srcPath(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: TextEditingController(text: sourcePath),
            readOnly: true,
            decoration: InputDecoration(
              labelText: getLocalizedString(context, 'sourcePath'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${getLocalizedString(context, 'totalFiles')}: $totalFiles'),
      ],
    );
  }

  Row dropZone(BuildContext context) {
    return Row(
      children: [
        srcDropZone(context),
        SizedBox(width: 16),
        dstDropZone(context),
      ],
    );
  }

  Expanded dstDropZone(BuildContext context) {
    return Expanded(
      child: DropTarget(
        onDragDone: (details) async {
          if (details.files.isNotEmpty) {
            String droppedPath = details.files.first.path;
            bool isDir = await io.FileSystemEntity.isDirectory(droppedPath);
            setState(() {
              destinationPath = isDir ? droppedPath : p.dirname(droppedPath);
            });
          }
        },
        onDragEntered: (details) {
          setState(() {
            _isDraggingDestination = true;
          });
        },
        onDragExited: (details) {
          setState(() {
            _isDraggingDestination = false;
          });
        },
        child: Container(
          color: _isDraggingDestination ? Colors.green[100] : Colors.grey[200],
          child: Center(
            child: Text(
              getLocalizedString(context, 'destinationDrag'),
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Expanded srcDropZone(BuildContext context) {
    return Expanded(
      child: DropTarget(
        onDragDone: (details) async {
          if (details.files.isNotEmpty) {
            String droppedPath = details.files.first.path;
            bool isDir = await io.FileSystemEntity.isDirectory(droppedPath);
            setState(() {
              sourcePath = isDir ? droppedPath : p.dirname(droppedPath);
            });
            if (sourcePath.isNotEmpty) {
              await _updateFileCount(sourcePath);
            }
          }
        },
        onDragEntered: (details) {
          setState(() {
            _isDraggingSource = true;
          });
        },
        onDragExited: (details) {
          setState(() {
            _isDraggingSource = false;
          });
        },
        child: Container(
          color: _isDraggingSource ? Colors.blue[100] : Colors.grey[200],
          child: Center(
            child: Text(
              getLocalizedString(context, 'sourceDrag'),
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
