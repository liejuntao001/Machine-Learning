%% CS294A/CS294W Stacked Autoencoder Exercise

%  Instructions
%  ------------
% 
%  This file contains code that helps you get started on the
%  sstacked autoencoder exercise. You will need to complete code in
%  stackedAECost.m
%  You will also need to have implemented sparseAutoencoderCost.m and 
%  softmaxCost.m from previous exercises. You will need the initializeParameters.m
%  loadMNISTImages.m, and loadMNISTLabels.m files from previous exercises.
%  
%  For the purpose of completing the assignment, you do not need to
%  change the code in this file. 
%
%%======================================================================
%% STEP 0: Here we provide the relevant parameters values that will
%  allow your sparse autoencoder to get good filters; you do not need to 
%  change the parameters below.
DISPLAY = true;
inputSize = 28 * 28;
numClasses = 10;
hiddenSizeL1 = 200;    % Layer 1 Hidden Size
hiddenSizeL2 = 200;    % Layer 2 Hidden Size
sparsityParam = 0.1;   % desired average activation of the hidden units.
                       % (This was denoted by the Greek alphabet rho, which looks like a lower-case "p",
                       %  in the lecture notes). 
lambda = 3e-3;         % weight decay parameter       
beta = 3;              % weight of sparsity penalty term       

%%======================================================================
%% STEP 1: Load data from the MNIST database
%
%  This loads our training data from the MNIST database files.

% Load MNIST database files
trainData = loadMNISTImages('train-images.idx3-ubyte');
trainLabels = loadMNISTLabels('train-labels.idx1-ubyte');

trainLabels(trainLabels == 0) = 10; % 一直没搞懂，为什么非要把标签0变为10？ Remap 0 to 10 since our labels need to start from 1

%%======================================================================
%% STEP 2: Train the first sparse autoencoder
%  This trains the first sparse autoencoder on the unlabelled STL training
%  images.
%  If you've correctly implemented sparseAutoencoderCost.m, you don't need
%  to change anything here.


%  Randomly initialize the parameters
sae1Theta = initializeParameters(hiddenSizeL1, inputSize);

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the first layer sparse autoencoder, this layer has
%                an hidden size of "hiddenSizeL1"
%                You should store the optimal parameters in sae1OptTheta

addpath minFunc/;
options = struct;
options.Method = 'lbfgs';
options.maxIter = 400;
options.display = 'on';
[sae1OptTheta, cost] =  minFunc(@(p)sparseAutoencoderCost(p,...
    inputSize,hiddenSizeL1,lambda,sparsityParam,beta,trainData),sae1Theta,options);%训练出第一层网络的参数
save('saves/step2.mat', 'sae1OptTheta');

if DISPLAY
  W1 = reshape(sae1OptTheta(1:hiddenSizeL1 * inputSize), hiddenSizeL1, inputSize);
  display_network(W1');
end




% -------------------------------------------------------------------------



%%======================================================================
%% STEP 3: Train the second sparse autoencoder
%  This trains the second sparse autoencoder on the first autoencoder
%  featurse.
%  If you've correctly implemented sparseAutoencoderCost.m, you don't need
%  to change anything here.
%  利用第一个稀疏自编码器的权重参数sae1OptTheta，得到输入数据的一阶特征表示  

[sae1Features] = feedForwardAutoencoder(sae1OptTheta, hiddenSizeL1, ...
                                        inputSize, trainData);

%  Randomly initialize the parameters
sae2Theta = initializeParameters(hiddenSizeL2, hiddenSizeL1);

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the second layer sparse autoencoder, this layer has
%                an hidden size of "hiddenSizeL2" and an inputsize of
%                "hiddenSizeL1"
%
%                You should store the optimal parameters in sae2OptTheta

[sae2OptTheta, cost] =  minFunc(@(p)sparseAutoencoderCost(p,...
    hiddenSizeL1,hiddenSizeL2,lambda,sparsityParam,beta,sae1Features),sae2Theta,options);%训练出第二层网络的参数
save('saves/step3.mat', 'sae2OptTheta');

figure;
if DISPLAY
  W11 = reshape(sae1OptTheta(1:hiddenSizeL1 * inputSize), hiddenSizeL1, inputSize);
  W12 = reshape(sae2OptTheta(1:hiddenSizeL2 * hiddenSizeL1), hiddenSizeL2, hiddenSizeL1);
  % TODO(zellyn): figure out how to display a 2-level network
%  display_network(log(W11' ./ (1-W11')) * W12');
%   W12_temp = W12(1:196,1:196);
%   display_network(W12_temp');
%   figure;
%   display_network(W12_temp');
end

% -------------------------------------------------------------------------


%%======================================================================
%% STEP 4: 用二阶特征训练softmax分类器 Train the softmax classifier
%  This trains the sparse autoencoder on the second autoencoder features.
%  If you've correctly implemented softmaxCost.m, you don't need
%  to change anything here.

%  利用第二个稀疏自编码器的权重参数sae2OptTheta，得到输入数据的二阶特征表示  
[sae2Features] = feedForwardAutoencoder(sae2OptTheta, hiddenSizeL2, ...
                                        hiddenSizeL1, sae1Features);

%  Randomly initialize the parameters
saeSoftmaxTheta = 0.005 * randn(hiddenSizeL2 * numClasses, 1);%这个参数拿来干嘛？计算softmaxCost函数吗？可以舍去！
                                                              %因为softmaxCost函数在softmaxExercise练习中已经实现，并且已经证明其梯度计算是正确的！


%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the softmax classifier, the classifier takes in
%                input of dimension "hiddenSizeL2" corresponding to the
%                hidden layer size of the 2nd layer.
%
%                You should store the optimal parameters in saeSoftmaxOptTheta 
%
%  NOTE: If you used softmaxTrain to complete this part of the exercise,
%        set saeSoftmaxOptTheta = softmaxModel.optTheta(:);

softmaxLambda = 1e-4;
numClasses = 10;
softoptions = struct;
softoptions.maxIter = 400;
softmaxModel = softmaxTrain(hiddenSizeL2,numClasses,softmaxLambda,...
                            sae2Features,trainLabels,softoptions);
saeSoftmaxOptTheta = softmaxModel.optTheta(:);%得到softmax分类器的权重参数

save('saves/step4.mat', 'saeSoftmaxOptTheta');

% -------------------------------------------------------------------------



%%======================================================================
%% STEP 5: 微调 Finetune softmax model

% Implement the stackedAECost to give the combined cost of the whole model
% then run this cell.

% Initialize the stack using the parameters learned
stack = cell(2,1);
stack{1}.w = reshape(sae1OptTheta(1:hiddenSizeL1*inputSize), ...
                     hiddenSizeL1, inputSize);
stack{1}.b = sae1OptTheta(2*hiddenSizeL1*inputSize+1:2*hiddenSizeL1*inputSize+hiddenSizeL1);
stack{2}.w = reshape(sae2OptTheta(1:hiddenSizeL2*hiddenSizeL1), ...
                     hiddenSizeL2, hiddenSizeL1);
stack{2}.b = sae2OptTheta(2*hiddenSizeL2*hiddenSizeL1+1:2*hiddenSizeL2*hiddenSizeL1+hiddenSizeL2);

% Initialize the parameters for the deep model
[stackparams, netconfig] = stack2params(stack);%把stack层（即：两个隐藏层）的权重参数变为一个向量stackparams
stackedAETheta = [ saeSoftmaxOptTheta ; stackparams ];% 得到微调前整个网络参数向量stackedAETheta，它包括softmax分类器那部分的参数向量saeSoftmaxOptTheta，且分类器那部分的参数放前面

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the deep network, hidden size here refers to the '
%                dimension of the input to the classifier, which corresponds 
%                to "hiddenSizeL2".
%
%  用BP算法微调，得到微调后的整个网络参数stackedAEOptTheta

[stackedAEOptTheta, cost] =  minFunc(@(p)stackedAECost(p,inputSize,hiddenSizeL2,...
                         numClasses, netconfig,lambda, trainData, trainLabels),...
                        stackedAETheta,options);%训练出第三层网络的参数
save('saves/step5.mat', 'stackedAEOptTheta');

figure;
if DISPLAY
  optStack = params2stack(stackedAEOptTheta(hiddenSizeL2*numClasses+1:end), netconfig);
  W11 = optStack{1}.w;
  W12 = optStack{2}.w;
  % TODO(zellyn): figure out how to display a 2-level network
  % display_network(log(1 ./ (1-W11')) * W12');
end



% -------------------------------------------------------------------------



%%======================================================================
%% STEP 6: Test 
%  Instructions: You will need to complete the code in stackedAEPredict.m
%                before running this part of the code
%

% Get labelled test images
% Note that we apply the same kind of preprocessing as the training set
testData = loadMNISTImages('t10k-images.idx3-ubyte');
testLabels = loadMNISTLabels('t10k-labels.idx1-ubyte');

testLabels(testLabels == 0) = 10; % Remap 0 to 10

[pred] = stackedAEPredict(stackedAETheta, inputSize, hiddenSizeL2, ...
                          numClasses, netconfig, testData);

acc = mean(testLabels(:) == pred(:));
fprintf('Before Finetuning Test Accuracy: %0.3f%%\n', acc * 100);

[pred] = stackedAEPredict(stackedAEOptTheta, inputSize, hiddenSizeL2, ...
                          numClasses, netconfig, testData);

acc = mean(testLabels(:) == pred(:));
fprintf('After Finetuning Test Accuracy: %0.3f%%\n', acc * 100);

% Accuracy is the proportion of correctly classified images
% The results for our implementation were:
%
% Before Finetuning Test Accuracy: 87.7%
% After Finetuning Test Accuracy:  97.6%
%
% If your values are too low (accuracy less than 95%), you should check 
% your code for errors, and make sure you are training on the 
% entire data set of 60000 28x28 training images 
% (unless you modified the loading code, this should be the case)