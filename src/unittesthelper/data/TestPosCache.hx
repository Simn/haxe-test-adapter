package unittesthelper.data;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;
#if !macro
import json2object.JsonParser;
#end

typedef TestPositions = Map<String, TestPos>;

class TestPosCache {
	public static inline var RESULT_FOLDER:String = ".unittest";
	public static inline var POS_FILE:String = "testPositions.json";
	static var INSTANCE:TestPosCache = new TestPosCache();

	var testPositions:TestPositions;
	var loaded:Bool;

	function new() {
		testPositions = new TestPositions();
		loadCache();
	}

	public static function addPos(testPos:TestPos) {
		INSTANCE.testPositions.set(testPos.location, testPos);
		INSTANCE.saveCache();
	}

	public static function getPos(location:String):TestPos {
		if (!INSTANCE.loaded) {
			INSTANCE.loadCache();
		}
		return INSTANCE.testPositions.get(location);
	}

	function saveCache() {
		File.saveContent(getTestPosFileName(), Json.stringify(testPositions, null, "    "));
	}

	function loadCache() {
		#if !macro
		var fileName:String = getTestPosFileName();
		var content:String = File.getContent(fileName);

		var parser:JsonParser<TestPositions> = new JsonParser<TestPositions>();
		testPositions = parser.fromJson(content, fileName);
		#end
	}

	public static function getTestPosFileName():String {
		return Path.join([RESULT_FOLDER, POS_FILE]);
	}
}
