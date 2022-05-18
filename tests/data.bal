import ballerina/file;
import ballerina/io;

function yamlDataGen() returns map<[string, json?, boolean]>|error {
    file:MetaData[] data = check file:readDir("tests/resources");
    map<[string, json?, boolean]> testMetaData = {};

    // Read the directory of the test cases
    foreach file:MetaData item in data {
        if !item.dir {
            continue;
        }
        file:MetaData[] testFiles = check file:readDir(item.absPath);

        if testFiles[0].dir {
            int i = 0;
            foreach file:MetaData subItem in testFiles {
                i += 1;
                check addTestCase(testMetaData, subItem, "#" + i.toString());
            }
        }
        else {
            check addTestCase(testMetaData, item);
        }
    }

    return testMetaData;
}

function addTestCase(map<[string, json?, boolean]> testMetaData, file:MetaData metaData, string? annexData = ()) returns error? {
    string dirPath = metaData.absPath + "/";
    string testCase = check io:fileReadString(dirPath + "===") + (annexData ?: "");
    string yamlPath = dirPath + "in.yaml";
    string jsonPath = dirPath + "in.json";
    boolean isStream = check file:test(dirPath + "stream", file:EXISTS);
    json expectedOutput =   check file:test(jsonPath, file:EXISTS)
                    ? check io:fileReadJson(jsonPath)
                    : ();
    testMetaData[testCase] = [yamlPath, expectedOutput, isStream];
}
