package flump.export {

import aspire.util.F;
import aspire.util.Log;

import flash.events.ErrorEvent;

import flash.filesystem.File;
import flash.utils.getTimer;

import flump.executor.Executor;
import flump.executor.Future;
import flump.export.formats.JSONFormat;
import flump.util.StringUtil;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

public class ExportController {

    protected var _confFile :File;
    protected var _conf :ProjectConf;
    protected var _importDirectory :File;
    protected var _projectDirty :Boolean; // true if project has unsaved changes
    protected static const log :Log = Log.getLog(ExportController);
    private var filesToImport : Vector.<File>;
    private var dirsToScan : uint;

    public function get projectName () :String {
        return (_confFile != null ? _confFile.name.replace(/\.flump$/i, "") : "Untitled Project");
    }

    protected function handleParseError (err :ParseError) :void {
        throw new Error("abstract");
    }

    protected function addDoc (status :DocStatus) :void {
        throw new Error("abstract");
    }

    protected function getDocs () :Array {
        throw new Error("abstract");
    }

    protected function readProjectConfig () :Boolean {
        if (_confFile == null) {
            return false;
        }
        try {
            var projJson :Object = JSONFormat.readJSON(_confFile);
            var fileVersion :* = projJson["fileVersion"];
            _conf = ProjectConf.fromJSON(projJson);
            if (fileVersion != _conf.fileVersion) setProjectDirty(true);
            _importDirectory = new File(_confFile.parent.resolvePath(_conf.importDir).nativePath);
            if (!_importDirectory.exists || !_importDirectory.isDirectory) {
                handleParseError(new ParseError(_confFile.nativePath, ParseError.CRIT,
                    "Import directory doesn't exist (" + _importDirectory.nativePath + ")"));
                return false;
            }
        } catch (e :Error) {
            if (e is ParseError) {
                handleParseError(ParseError(e));
            }
            handleParseError(new ParseError(_confFile.nativePath, ParseError.CRIT, "Unable to read configuration"));
            return false;
        }

        return true;
    }

    protected function setProjectDirty (val :Boolean) :void {
        _projectDirty = val;
    }

    protected function importFlashDocuments(base :File, exec :Executor) :void {
        dirsToScan = 0;
        filesToImport = new Vector.<File>();
        scanDirectory(base, exec);
    }

    private function scanDirectory(base :File, exec :Executor) : void {
        dirsToScan++;
        var future : Future = Files.list(base, exec);

        future.succeeded.add(function (files :Array) :void {
            if (exec.isShutdown) {
                return;
            }
            for each (var file : File in files) {
                if (StringUtil.startsWith(file.name, ".", "RECOVER_")) {
                    // Ignore hidden VCS directories, and recovered backups created by Flash
                    continue;
                }
                if (file.isDirectory) {
                    scanDirectory(file, exec);
                }
                else {
                    filesToImport.push(file);
                }
            }
            checkIfDone();
        });
        future.failed.add(function(event : ErrorEvent):void {
            log.error("Failed to scan directory " + event.text);
            checkIfDone();
        });
    }

    private function checkIfDone() : void {
        dirsToScan--;
        if (dirsToScan == 0) {
            importNextFlashDocument();
        }
    }

    private function importNextFlashDocument() : void {
        if (filesToImport.length > 0) {
            importFlashDocument( filesToImport.shift() );
        }
    }

    protected function importFlashDocument (file :File) :void {
        if (Files.getExtension(file) == "fla") {
            var startTime : uint = getTimer();
            var importPathLen :int = _importDirectory.nativePath.length + 1;
            var name :String = file.nativePath.substring(importPathLen).replace(new RegExp("\\" + File.separator, "g"), "/");
            name = name.substr(0, name.lastIndexOf("."));
            var load :Future = new FlaLoader().load(name, file);

            const status :DocStatus = new DocStatus(name, Ternary.UNKNOWN, Ternary.UNKNOWN);
            status.parseStartTime = startTime;
            addDoc(status);
            load.succeeded.add(F.argify(F.bind(docLoadSucceeded, status, F._1), 1));
            load.failed.add(F.argify(F.bind(docLoadFailed, file, status, F._1), 1));
        }
        else {
            importNextFlashDocument();
        }
    }

    protected function docLoadSucceeded(doc :DocStatus, lib :XflLibrary) :void {
        doc.lib = lib;
        for each (var err :ParseError in lib.getErrors()) handleParseError(err);
        doc.updateValid(Ternary.of(lib.valid));
        doc.parseTime = ((getTimer() - doc.parseStartTime) / 1000).toFixed(1);
        importNextFlashDocument();
    }

    protected function docLoadFailed(file :File, doc :DocStatus, err :*) :void {
        doc.updateValid(Ternary.FALSE);
        doc.parseTime = ((getTimer() - doc.parseStartTime) / 1000).toFixed(1);
        importNextFlashDocument();
    }

    /** returns all libs if all known flash docs are done loading, else null */
    protected function getLibs () :Vector.<XflLibrary> {
        var libs :Vector.<XflLibrary> = new <XflLibrary>[];
        for each (var status :DocStatus in getDocs()) {
            if (status.lib == null) return null; // not done loading yet
            libs[libs.length] = status.lib;
        }
        return libs;
    }

}
}
