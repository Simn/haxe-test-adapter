package _testadapter.tink_unittest;

import _testadapter.data.Data;
import _testadapter.data.TestResults;

using tink.CoreApi;

class Reporter implements tink.testrunner.Reporter {
	var reporter:tink.testrunner.Reporter;
	var currentSuiteId:SuiteId;
	var currentCaseId:TestIdentifier;

	public var testResults:TestResults;

	public function new(baseFolder:String, reporter:tink.testrunner.Reporter) {
		testResults = new TestResults(baseFolder);
		if (reporter == null) {
			reporter = new tink.testrunner.Reporter.BasicReporter();
		}
		this.reporter = reporter;
	}

	public function report(type:tink.testrunner.Reporter.ReportType):Future<Noise> {
		switch (type) {
			case BatchStart:
			case BatchFinish(_):
				testResults.save();
			case SuiteStart(info, _):
				currentSuiteId = SuiteNameAndPos(info.name, info.pos.fileName, info.pos.lineNumber - 1);
			case CaseStart(info, _):
				currentCaseId = TestNameAndPos(info.name, info.pos.fileName, info.pos.lineNumber - 1);
			case Assertion(assertion):
				switch (assertion.holds) {
					case Success(_):
						testResults.add(currentSuiteId, currentCaseId, 0, TestState.Success);
					case Failure(msg):
						if (msg == null) {
							msg = assertion.description;
						}
						testResults.add(currentSuiteId, currentCaseId, 0, TestState.Failure, msg, assertion.pos.lineNumber - 1);
				}
			case CaseFinish(result):
				switch (result.result) {
					case Failed(msg):
						testResults.add(currentSuiteId, currentCaseId, 0, TestState.Error, msg.toString(), msg.pos.lineNumber - 1);
					case Succeeded(asserts):
						if ((asserts == null) || (asserts.length <= 0)) {
							testResults.add(currentSuiteId, currentCaseId, 0, TestState.Success);
						}
					case Excluded:
						testResults.add(currentSuiteId, currentCaseId, 0, TestState.Ignore);
				}
			case SuiteFinish(_):
		}
		return reporter.report(type);
	}
}
