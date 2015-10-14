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
    private const _loader :Executor = new Executor();
    private var _library :XflLibrary;
    private static const log :Log = Log.getLog(FlaLoader);

    public function load (name :String, file :File) :Future {
        log.info("Loading fla", "path", file.nativePath, "name", name);

        this.file = file;

        future = new FutureTask();
        _library = new XflLibrary(name);

        const swfFile :File = new File(Files.replaceExtension(file, "swf"));
        const loadSwfFile :Future = Files.load(swfFile, null);
        loadSwfFile.succeeded.add(onSwfFileLoaded);
        loadSwfFile.failed.add(onError);
        return future;
    }

    private function onSwfFileLoaded(data :ByteArray) : void {
        md5 = MD5.hashBytes(data);
        const loadSwf :Future = new SwfLoader().loadFromBytes(data);
        loadSwf.succeeded.add(onSwfBytesLoaded);
        loadSwf.failed.add(onError);
    }

    private function onSwfBytesLoaded(loadedSwf :LoadedSwf) :void {
        swf = loadedSwf;
        const loadZip :Future = Files.load(file, _loader);
        loadZip.succeeded.add(onFlaLoaded);
        loadZip.failed.add(onError);
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

}
}
