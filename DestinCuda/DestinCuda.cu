#include "AdviceData.h"
#include "DestinData.h"

#include <iostream>
#include <stdio.h>
#include <vector>
#include <fstream>
#include <ctime>
#include <sstream>
#include <sys/stat.h>
#include <math.h>

#ifdef _WIN32
#include <direct.h>
#else
// Linux only requirements...
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#endif

using namespace std;

void PrintHelp()
{
    // ***************************
    // Print out how to use DeSTIN
    // ***************************

    cout << "Usage: DestinCuda CodeWord MAXCNT LayerToShow ParamsFile TrainingDataFile DestinOutputFile TargetDirectory [OutputDistillationLevel]" << endl;
    cout << "Where:" << endl;
    cout << "    CodeWord is greater than 1000 but must have 11 digits RRRR XX YYYYY" << endl;
    cout << "        RRRR >= 0000 to 9999 where 0000 is real random time" << endl;
    cout << "        XX    = 01 to 10 number of classes" << endl;
    cout << "        YYYYY = 00000 to 99999 number of examples of each class." << endl;
    cout << "                00000 means RANDOMLY PICK EXAMPLES until we finish clustering, period, up to max iterations." << endl;
    cout << "        RRRRXXYYYYY where RRRR is reserved, XX is number of classes, YYYYY is number of examples" << endl;
    cout << "    MAXCNT is the number of digits we show it to train the unsupervised DeSTIN architecture" << endl;
    cout << "    LayerToShow = layer written to output file; it is given as S:E:O:P:T where " << endl;
    cout << "        S = first layer to write" << endl;
    cout << "        E = last layer to write" << endl;
    cout << "        O = offset for movements to write" << endl;
    cout << "        P = period of movements to write" << endl;
    cout << "        T = type.  Nothing (and no !) is beliefs.  Type can be: " << endl;
    cout << "            A is belief in advice states computed by tabular method." << endl;
    cout << "            N is belief in advice states computed by neural network function approximator." << endl;
    cout << "            L is belief in advice states computed by linear function approximator." << endl;
    cout << "    ParamsFile is a file that has the run parameters" << endl;
    cout << "    TrainingDataFile is the binary data file for training.  A testing file with the SAME NAME and appended with _TESTING is assumed" << endl;
    cout << "    DestinOutputFile is the name of the DeSTIN network output file for saving." << endl;
    cout << "         Use -D as default, which is the experiment number with a .dat at the end, in the ../DiagnosticData directory" << endl;
    cout << "    TargetDirectory is where we want to put the MAIN OUTPUT DATA FILES.  We ALWAYS write an experiment marker to the " << endl;
    cout << "        ../DiagnosticData area.  But if you are writing out a lot of data you can specify another directory." << endl;
    cout << "        Put D for default which is the ../DiagnosticData area." << endl;
    cout << "    [OutputDistillationLevel] is optional.  If this exists it must be a number and currently its got to be 0.  "<<endl;
    cout << "        0 = regular outputs with a lot of details about movements and processing: this is our input to SampleAndStack"<<endl;
    cout << "        1 = outputs compatible with the regular distilled output of SampleAndStack. If you use this you can skip SampleAndStack.exe" << endl;
    cout << endl;
    cout << "-OR-" << endl;
    cout << endl;
    cout << "Usage: DestinCuda -F InputNetworkFile LayerToShow ParamsFile TrainingDataFile DestinOutputFile TargetDirectory [OutputDistillationLevel]" << endl;
    cout << "Where:" << endl;
    cout << "    -F signifies use a saved DeSTIN network file " << endl;
    cout << "    InputNetworkFile is the NAME of the saved DeSTIN network file" << endl;
    cout << "    All others are as in first usage type" << endl;
    cout << endl;
}

bool FileExists(string strFilename)
{
    // **************************
    // Does the given file exists
    // **************************
    // For detailed information look the return values of stat

    struct stat stFileInfo;
    bool blnReturn;
    int intStat;

    // Attempt to get the file attributes
    intStat = stat(strFilename.c_str(),&stFileInfo);
    if(intStat == 0) {
        // File exists
        blnReturn = true;
    }
    else
    {
        // File not exists or no permission
        blnReturn = false;
    }

    return(blnReturn);
}

string GetNextFileForDiagnostic()
{
    // *************************************
    // Find next available experimental file
    // *************************************
    // Check if there is a previous experiment inside ../DiagnosticData

    string strFileName;
    int iExperimentNumber=-1;
    bool bFileFound = true;
    while ( bFileFound )
    {
        iExperimentNumber++;
        stringstream buffer;
        buffer << "../DiagnosticData/DestinDiagnostics" << iExperimentNumber << ".csv";
        strFileName =  buffer.str();

        bFileFound = FileExists(strFileName);
    }

    return strFileName;
}

int MainDestinExperiments(int argc, char* argv[])
{
    // ********************************************
    // Main experiment of DeSTIN (Also called main)
    // ********************************************

    // File for diagnostic
    string strDiagnosticFileName;
    strDiagnosticFileName = GetNextFileForDiagnostic();

    // arguments processing

    // For debug information we output the command line to our Diagnostic file.
    string strCommandLineData = "";
    for( int i=0; i<argc; i++ )
    {
        strCommandLineData += argv[i];
        strCommandLineData += " ";
    }

    // Argument: DestinOutputFile or InputNetworkFile
    bool bCreateFromFile;
    string strDestinNetworkFileToRead;
    string strDestinNetworkFileToWrite;
    string FirstArg = argv[1];
    if ( FirstArg=="-F" )
    {
        // Argument: InputNetworkFile
        bCreateFromFile = true;
        strDestinNetworkFileToRead = argv[2];  // we read from this file...

        if ( !FileExists( strDestinNetworkFileToRead ) )
        {
            cout << "designated input network file named " << strDestinNetworkFileToRead.c_str() << " does not exist" << endl;
            return 0;
        }
    }
    else
    {
        // Argument: DestinOutputFile
        bCreateFromFile = false;
        strDestinNetworkFileToWrite = argv[6]; // we write to this file, and then we read from it too!!
        if ( strDestinNetworkFileToWrite == "-D" )
        {
            // If given -D
            strDestinNetworkFileToWrite=strDiagnosticFileName + "DestinNetwork.dat";
            cout << "Writing to default destin file name..." << endl;
        }
        strDestinNetworkFileToRead = strDestinNetworkFileToWrite;
    }

    // Argument: LayerToShow
    // Structure of processing S:E:O:P:T
    // List of default values
    int FirstLayerToShowHECK = 3;
    int LastLayerToShow = FirstLayerToShowHECK;
    int iMovementOutputOffset = 0;
    int iMovementOutputPeriod = 1;
    OutputTypes eTypeOfOutput = eBeliefs;

    string sLayerSpecs = argv[3];
    int iColon = sLayerSpecs.find(":");
    if ( iColon == -1 || sLayerSpecs.substr(iColon).empty() )  //first layer = last layer, and no sampling specified.
    {
        // S
        FirstLayerToShowHECK=atoi(sLayerSpecs.c_str());
        LastLayerToShow=FirstLayerToShowHECK;
    }
    else
    {
        // S:E
        FirstLayerToShowHECK=atoi(sLayerSpecs.substr(0,1).c_str());
        LastLayerToShow=atoi(sLayerSpecs.substr(iColon+1,1).c_str());
        sLayerSpecs = sLayerSpecs.substr(iColon+1);
        iColon = sLayerSpecs.find(":");
        if ( iColon!=-1 || !( sLayerSpecs.substr(iColon).empty() ) )
        {
            //S:E:O
            sLayerSpecs = sLayerSpecs.substr(iColon+1);
            iMovementOutputOffset = atoi(sLayerSpecs.substr(0,1).c_str());
            iColon = sLayerSpecs.find(":");
            if ( iColon!=-1 || !( sLayerSpecs.substr(iColon).empty() ) )
            {
                //S:E:O:P
                sLayerSpecs = sLayerSpecs.substr(iColon+1);
                iMovementOutputPeriod = atoi(sLayerSpecs.substr(0,1).c_str());
                iColon = sLayerSpecs.find(":");
                if ( iColon!=-1 || !( sLayerSpecs.substr(iColon).empty() ) )
                {
                    //S:E:O:P:T
                    sLayerSpecs = sLayerSpecs.substr(iColon+1);
                    if ( sLayerSpecs.substr(0,1)=="A" )
                    {
                        eTypeOfOutput = eBeliefInAdviceTabular;
                    }
                    else if ( sLayerSpecs.substr(0,1)=="B" )
                    {
                        eTypeOfOutput = eBeliefs;
                    }
                    else if ( sLayerSpecs.substr(0,1)=="N" )
                    {
                        eTypeOfOutput = eBeliefInAdviceNNFA;
                    }
                    else if ( sLayerSpecs.substr(0,1)=="L" )
                    {
                        eTypeOfOutput = eBeliefInAdviceLinearFA;
                    }
                    else
                    {
                        cout << "Do not understand the output type " << sLayerSpecs.c_str() << endl;
                        return 0;
                    }
                }
            }
        }
    }

    // Argument: TargetDirectory
    // A given location instead or default
    string strDiagnosticFileNameForData;
    string strArg7 = argv[7];
    if ( strArg7 == "D" )
    {
        strDiagnosticFileNameForData = strDiagnosticFileName;
    }
    else
    {
        // Buffer with path + filename where to put diagnostic data
        stringstream buffer;
        buffer << strArg7.c_str() << "/" << strDiagnosticFileName;
        strDiagnosticFileNameForData = buffer.str();
    }

    // Optional argument: OutputDistillationLevel
    // This will write out a distilled movement log file this movement log matches that what SampleAndStack would produce.
    int OutputDistillationLevel = 0; //default level
    if ( argc == 9 )
    {
        OutputDistillationLevel = atoi(argv[8]);
    }

    // **********************
    // Loading data source(s)
    // **********************
    // Arguments: TrainingDataFile
    // Load the training file for DeSTIN
    string strDestinTrainingFileName = argv[5];

    // Data object containing source training
    DestinData DataSourceForTraining;

    int NumberOfUniqueLabels;
    DataSourceForTraining.LoadFile(strDestinTrainingFileName.c_str());
    NumberOfUniqueLabels = DataSourceForTraining.GetNumberOfUniqueLabels();
    if ( NumberOfUniqueLabels==0 )
    {
        cout << "There seems to be something off with data source " << strDestinTrainingFileName.c_str() << endl;
        return 0;
    }

    // A vector with all the labels of the data source
    vector<int> vLabelList;
    DataSourceForTraining.GetUniqueLabels(vLabelList);

    // Load the test file for DeSTIN
    string strTesting = strDestinTrainingFileName;
    strTesting = strTesting + "_TESTING";
    // Data object of test source
    DestinData DataSourceForTesting;

    DataSourceForTesting.LoadFile((char*)(strTesting.c_str()));
    if ( DataSourceForTesting.GetNumberOfUniqueLabels()!=NumberOfUniqueLabels )
    {
        cout << "Test set does not have the same number of labels as train set " << endl;
        return 0;
    }
    // end of data loading

    // now get the file creation parameters
    int iNumberOfExamplesFromEachLabel;
    int MAX_CNT = 1000;
    int iTestSequence = 0;
    string ParametersFileName;
    vector< pair<int,int> > vIndicesAndGTLabelToUse;
    vector< pair<int,int> > LabelsAndIndicesForUse;

    // When TestSequence >= 1000 we will interpret it differently
    int NumberOfUniqueLabelsToUse;

    if ( bCreateFromFile==false )
    {
        // Argument: MAXCNT
        MAX_CNT=atoi(argv[2]);
        // Argument: CodeWord
        iTestSequence=atoi(argv[1]);
        string sBuff=argv[1];

        if (sBuff.length() != 11 )
        {
            PrintHelp();
            return 0;
        }

        string sNumInp;
        sNumInp="";

        int kj=0;
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];

        // if the first 4 digits are 0000 make a TRUE random, otherwise use the complete number.
        int iReserve = atoi( sNumInp.c_str() );
        if ( iReserve == 0 )
        {
            srand( time(NULL) );
        }
        else
        {
            int iRandSeed = iTestSequence;
            srand( (unsigned int)iRandSeed );
        }

        // next two digits = number of inputs
        sNumInp = "";
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        NumberOfUniqueLabelsToUse = atoi( sNumInp.c_str() );

        sNumInp = "";
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        sNumInp = sNumInp+sBuff[kj++];
        iNumberOfExamplesFromEachLabel=atoi( sNumInp.c_str() );

        // if iNumberOfExamplesFromEachLabel is 0 we randomly pick examples from the available
        // classes and only show them ONE TIME

        // Generate the examples from the dictates given here.
        if ( iNumberOfExamplesFromEachLabel > 0 )
        {
            for(int iLabel=0;iLabel<NumberOfUniqueLabelsToUse;iLabel++)
            {
                vector<int> IndicesForThisLabel;
                DataSourceForTraining.GetIndicesForThisLabel(iLabel,IndicesForThisLabel);

                for(int jj=0;jj<iNumberOfExamplesFromEachLabel;jj++)
                {
                    pair<int,int> P;
                    P.first = IndicesForThisLabel[jj];
                    P.second = iLabel;
                    LabelsAndIndicesForUse.push_back(P);
                }
            }
        }
        else
        {
            // In this mode, simply get ALL the examples for this class and put them in
            // LabelsAndIndicesForUse. BUT, skip according to the value of DestinTrainSampleStep
            int FirstTrainingIndex = 0;  // this was set to 1 for the ICMLA tests, I think.
            for(int iLabel=0;iLabel<NumberOfUniqueLabelsToUse;iLabel++)
            {
                int DestinTrainSampleStep = 25;
                vector<int> IndicesForThisLabel;
                DataSourceForTraining.GetIndicesForThisLabel(iLabel,IndicesForThisLabel);
                for(int jj=FirstTrainingIndex;jj<IndicesForThisLabel.size();jj=jj+DestinTrainSampleStep)
                {
                    cout << "Get sample " << jj << " for destin network" << endl;
                    pair<int,int> P;
                    P.first = IndicesForThisLabel[jj];
                    P.second = iLabel;
                    LabelsAndIndicesForUse.push_back(P);
                }
            }
            iNumberOfExamplesFromEachLabel = LabelsAndIndicesForUse.size()/NumberOfUniqueLabelsToUse;
        }

        //Now generate MAX_CNT+1000 random numbers from 0 to LabelsAndIndicesForUse-1
        // and use these to populate vIndicesAndGTLabelToUse
        int iChoice;
        int Picked[10];
        for(int jj=0;jj<10;jj++)
        {
            Picked[jj]=0;
        }
        iChoice=RAND_MAX;
        int Digit;
        for(int jj=0;jj<MAX_CNT;jj++)
        {
            //pick the digit first...
            Digit=rand() % NumberOfUniqueLabelsToUse;
            iChoice=Digit*iNumberOfExamplesFromEachLabel;
            iChoice = iChoice+rand()%iNumberOfExamplesFromEachLabel;

//                  iChoice = rand() % LabelsAndIndicesForUse.size();
            pair<int,int> P;
            P = LabelsAndIndicesForUse[iChoice];
            //LabelsAndIndicesForUse.erase( LabelsAndIndicesForUse.begin()+iChoice ); //erase the chosen one
            vIndicesAndGTLabelToUse.push_back( P );
            Picked[P.second]=1;
        }
        cout << "------------------" << endl;
        for(int jj=0;jj<10;jj++)
        {
            cout << jj << "," << Picked[jj] << endl;
        }
        cout << "------------------" << endl;

        // Get the destin network parameters from a run file...
        ParametersFileName=argv[4];


    }  //check on bCreateFromFile==false
    else
    {
        // TODO: We want to create the network from an INPUT FILE!
        cout << "We want to create the network from an INPUT FILE!" << endl;
    }

    return 0;
}

int main(int argc, char* argv[])
{
    // ********************
    // Startup check DeSTIN
    // ********************

    if ( argc==8 || argc==9 )
    {
        return MainDestinExperiments(argc,argv);
    }
    else
    {
        PrintHelp();
        return 0;
    }
}
