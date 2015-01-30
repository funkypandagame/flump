//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Log;

import com.adobe.crypto.MD5;

import deng.fzip.FZip;

import flash.filesystem.File;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;
import flump.executor.load.LoadedSwf;
import flump.executor.load.SwfLoader;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

public class FlaLoader
{
    private var file : File;
    private var md5 : String;
    private var swf : LoadedSwf;
    private var future : FutureTask;

    public function load (name :String, file :File) :Future {
        log.info("Loading fla", "path", file.nativePath, "name", name);

        this.file = file;

        future = new FutureTask();
        _library = new XflLibrary(name);

        const swfFile :File = new File(Files.replaceExtension(file, "swf"));
        const loadSwfFile :Future = Files.load(swfFile, null);
        loadSwfFile.succeeded.connect(onSwfFileLoaded);
        loadSwfFile.failed.connect(onError);
        return future;
    }

    private function onSwfFileLoaded(data :ByteArray) : void {
        md5 = MD5.hashBytes(data);
        const loadSwf :Future = new SwfLoader().loadFromBytes(data);
        loadSwf.succeeded.connect(onSwfBytesLoaded);
        loadSwf.failed.connect(onError);
    }

    private function onSwfBytesLoaded(loadedSwf :LoadedSwf) :void {
        swf = loadedSwf;
        const loadZip :Future = Files.load(file, _loader);
        loadZip.succeeded.connect(onFlaLoaded);
        loadZip.failed.connect(onError);
    }

    private function onFlaLoaded(data :ByteArray) :void {
        const zip :FZip = new FZip();
        zip.loadBytes(data);
        _library.parseFlaFile(zip, swf, md5);
        future.succeed(_library);
        _loader.shutdown();
    }

    private function onError(error :Error) :void {
        _library.addTopLevelError(ParseError.CRIT, error.message, error);
        future.succeed(_library);
        _loader.shutdown();
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(FlaLoader);
}
}
