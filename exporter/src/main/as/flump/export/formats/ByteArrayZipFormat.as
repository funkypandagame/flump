package flump.export.formats {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.LibraryLoader;
import flump.export.Atlas;
import flump.export.AtlasUtil;
import flump.export.ExportConf;
import flump.export.Files;
import flump.xfl.XflLibrary;

public class ByteArrayZipFormat extends PublishFormat
{
    public static const NAME :String = "ByteArrayZip";

    public var outputFile :File;

    public function ByteArrayZipFormat (destDir :File, libs :Vector.<XflLibrary>, conf :ExportConf,
            projectName :String) {
        super(destDir, libs, conf, projectName);
        if (conf.name != null) {
            outputFile = _destDir.resolvePath(conf.name + "/" + location + ".zip");
        } else {
            outputFile = _destDir.resolvePath(location + ".zip");
        }
    }

    override public function get modified () :Boolean {
        if (!outputFile.exists) return true;

        const zip :FZip = new FZip();
        zip.loadBytes(Files.read(outputFile));
        const md5File :FZipFile = zip.getFileByName("md5");
        const md5 :String = md5File.content.readUTFBytes(md5File.content.length);
        return md5 != this.md5;
    }

    override public function publish() :void {
        const zip :FZip = new FZip();

        const atlases :Vector.<Atlas> = createAtlases();

        for each (var atlas :Atlas in atlases) {
            var bytes :ByteArray = new ByteArray();
            AtlasUtil.writePNG(atlas, bytes);
            zip.addFile(atlas.filename, bytes);
        }
        LibraryLoader.registerByteArrayClassAliases();
        var ba : ByteArray = new ByteArray();
        ba.writeObject(createMold(atlases));
        zip.addFile(LibraryLoader.BYTEARRAY_LIBRARY_LOCATION, ba);

        addToZip(zip, LibraryLoader.MD5_LOCATION, md5);

        addToZip(zip, LibraryLoader.VERSION_LOCATION, LibraryLoader.VERSION);

        Files.write(outputFile, function (out :IDataOutput) :void {
            zip.serialize(out, /*includeAdler32=*/true);
        });
    }

    private static function addToZip(zip : FZip, name :String, data : String) :void {
        const bytes :ByteArray = new ByteArray();
        bytes.writeUTFBytes(data);
        zip.addFile(name, bytes);
    }

}
}
