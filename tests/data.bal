import ballerina/file;
import ballerina/io;

function yamlDataGen() returns map<[string, json, boolean, boolean]>|error {
    file:MetaData[] data = check file:readDir("tests/resources");
    map<[string, json, boolean, boolean]> testMetaData = {};

    // Read the directory of the test cases
    foreach file:MetaData item in data {
        if !item.dir {
            continue;
        }
        file:MetaData[] testFiles = check file:readDir(item.absPath);
        string dirName = item.absPath.substring(<int>item.absPath.indexOf("resources") + 10);

        if testFiles[0].dir {
            foreach file:MetaData subItem in testFiles {
                check addTestCase(testMetaData, subItem, dirName,
                    "#" + (subItem["absPath"][subItem["absPath"].length() - 4] == "/" 
                        ? subItem["absPath"].substring(subItem["absPath"].length() - 3)
                        : subItem["absPath"].substring(subItem["absPath"].length() - 2)));
            }
        }
        else {
            check addTestCase(testMetaData, item, dirName);
        }
    }

    return testMetaData;
}

function addTestCase(map<[string, json, boolean, boolean]> testMetaData, file:MetaData metaData, string dirName, string? annexData = ()) returns error? {
    string dirPath = metaData.absPath + "/";
    string testCase = string `${dirName}${annexData ?: ""}-${check io:fileReadString(dirPath + "===")}`;
    string yamlPath = dirPath + "in.yaml";
    string jsonPath = dirPath + "in.json";
    boolean isStream = check file:test(dirPath + "stream", file:EXISTS);
    boolean isError = false;
    json expectedOutput = ();
    if check file:test(jsonPath, file:EXISTS) {
        expectedOutput = check io:fileReadJson(jsonPath);
    }
    else {
        isError = true;
    }

    testMetaData[testCase] = [yamlPath, expectedOutput, isStream, isError];
}
