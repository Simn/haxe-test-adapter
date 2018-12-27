import haxe.io.Path;
import js.Object;
import js.Promise;
import unittesthelper.data.SuiteTestResultData;
import unittesthelper.data.TestResultData;
import vscode.EventEmitter;
import vscode.Event;
import vscode.FileSystemWatcher;
import vscode.OutputChannel;
import vscode.Uri;
import vscode.WorkspaceFolder;
import vscode.testadapter.api.TestAdapter;
import vscode.testadapter.api.data.TestInfo;
import vscode.testadapter.api.data.TestState;
import vscode.testadapter.api.data.TestSuiteInfo;
import vscode.testadapter.api.event.TestLoadEvent;
import vscode.testadapter.api.event.TestEvent;
import vscode.testadapter.util.Log;

class HaxeTestAdapter implements TestAdapter {
	public var workspaceFolder:WorkspaceFolder;

	var testsEmitter:EventEmitter<TestLoadEvent>;
	var testStatesEmitter:EventEmitter<TestEvent>;
	var autorunEmitter:EventEmitter<Void>;
	var suiteData:SuiteTestResultData;
	var channel:OutputChannel;
	var log:Log;
	var dataWatcher:FileSystemWatcher;

	public function new(workspaceFolder:WorkspaceFolder, channel:OutputChannel, log:Log) {
		this.workspaceFolder = workspaceFolder;
		this.channel = channel;
		this.log = log;

		channel.appendLine('Starting test adapter for ${workspaceFolder.name}');

		testsEmitter = new EventEmitter<TestLoadEvent>();
		testStatesEmitter = new EventEmitter<TestEvent>();
		autorunEmitter = new EventEmitter<Void>();

		// TODO is there a better way to make getters??
		Object.defineProperty(this, "tests", {
			get: function() {
				return testsEmitter.event;
			}
		});
		Object.defineProperty(this, "testStates", {
			get: function() {
				return testStatesEmitter.event;
			}
		});
		Object.defineProperty(this, "autorun", {
			get: function() {
				return autorunEmitter.event;
			}
		});

		var fileName:String = TestResultData.getTestDataFileName(workspaceFolder.uri.fsPath);

		dataWatcher = Vscode.workspace.createFileSystemWatcher(fileName, false, false, true);
		dataWatcher.onDidChange(function(uri:Uri) {
			load();
			updateAll();
		});
	}

	/**
		Start loading the definitions of tests and test suites.
		Note that the Test Adapter should also watch source files and the configuration for changes and
		automatically reload the test definitions if necessary (without waiting for a call to this method).
		@returns A promise that is resolved when the adapter finished loading the test definitions.
	**/
	public function load():Thenable<Void> {
		testsEmitter.fire({type: Started});
		suiteData = TestResultData.loadData(workspaceFolder.uri.fsPath);
		if (suiteData == null) {
			testsEmitter.fire({type: Finished, suite: null, errorMessage: "invalid test result data"});
			return null;
		}
		var suiteChilds:Array<TestSuiteInfo> = [];
		var suiteInfo:TestSuiteInfo = {
			type: "suite",
			label: suiteData.name,
			id: suiteData.name,
			children: suiteChilds
		};
		for (clazz in suiteData.classes) {
			var classChilds:Array<TestInfo> = [];
			var classInfo:TestSuiteInfo = {
				type: "suite",
				label: clazz.name,
				id: clazz.name,
				children: classChilds
			};
			for (test in clazz.tests) {
				var testInfo:TestInfo = {
					type: "test",
					id: clazz.name + "." + test.name,
					label: test.name,
				};
				if (test.file != null) {
					testInfo.file = Path.join([workspaceFolder.uri.fsPath, test.file]);
					testInfo.line = test.line;
				}
				classChilds.push(testInfo);
			}
			suiteChilds.push(classInfo);
		}
		testsEmitter.fire({type: Finished, suite: suiteInfo});
		updateAll();
		channel.appendLine("Loaded tests results");
		return Promise.resolve();
	}

	function updateAll() {
		if (suiteData == null) {
			return;
		}
		for (clazz in suiteData.classes) {
			for (test in clazz.tests) {
				var testState:TestState;
				switch (test.state) {
					case Success:
						testState = Passed;
					case Failure:
						testState = Failed;
					case Error:
						testState = Failed;
					case Ignore:
						testState = Skipped;
				}
				testStatesEmitter.fire({
					type: Test,
					test: clazz.name + "." + test.name,
					state: testState,
					message: test.errorText
				});
			}
		}
	}

	/**
		Run the specified tests.
		@param tests An array of test or suite IDs. For every suite ID, all tests in that suite are run.
		@returns A promise that is resolved when the test run is completed.
	**/
	public function run(tests:Array<String>):Thenable<Void> {
		log.info("run tests " + tests);
		channel.appendLine('Run tests ($tests): not implemented!');
		updateAll();
		return null;
	}

	/**
		Run the specified tests in the debugger.
		@param tests An array of test or suite IDs. For every suite ID, all tests in that suite are run.
		@returns A promise that is resolved when the test run is completed.
	**/
	public function debug(tests:Array<String>):Thenable<Void> {
		log.info("debug tests " + tests);
		channel.appendLine('Debug tests ($tests): not implemented!');
		return null;
	}

	/**
		Stop the current test run.
	**/
	public function cancel() {
		log.info("cancel tests");
		channel.appendLine("Cancel tests: not implemented!");
	}

	// TODO replace with getter
	public function tests():Event<TestLoadEvent> {
		return testsEmitter.event;
	}

	// TODO replace with getter
	public function testStates():Event<TestEvent> {
		return testStatesEmitter.event;
	}

	// TODO replace with getter
	public function autorun():Event<Void> {
		return autorunEmitter.event;
	}
}