#  ReadMe
This file explains how to test music recognition algorithm based on short-time Fourier transformc (STFT).
STFT is achieved by frame-wise FFT from EZAudioFFT library.

### Step 1: In ViewController.h
#### replace EZAudioFFTRolling with normal EZAudioFFT in ViewController.h file
    ```
    //
    // Used to calculate a normal FFT of the incoming audio data.
    //
    @property (nonatomic, strong) EZAudioFFT *fft;
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:FFTViewControllerFFTWindowSize sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];
    ```
    
### Step 2: In ViewController.m
#### define a new global array for audio data, named as audioData[AUDIODATALENGTH]
    ```
    #define AUDIODATALENGTH 4096
    float audioData[AUDIODATALENGTH];
    ```

#### Add constant array storing fundemantal frequency of 88 piano keys
    ```
    static const float freqBase[88] = {
    // Note A0 - B0
    27.5, 29.135235, 30.867706,
    // Note C1 - B1
    32.703195, 34.647828, 36.708095, 38.890872, 41.203444, 43.653528,
    46.249302, 48.999429, 51.913087, 55, 58.27047, 61.735412,
    // Note C2 - B2
    65.406391, 69.295657, 73.416191, 77.781745, 82.406889, 87.307057,
    92.498605, 97.998858, 103.82617, 110, 116.54094, 123.47082,
    // Note C3 - B3
    130.812782, 138.591315, 146.832383, 155.563491, 164.813778, 174.614115,
    184.997211, 195.997717, 207.652348, 220.000000, 233.081880, 246.941650,
    // Note C4 - B4
    261.625565, 277.182630, 293.664767, 311.126983, 329.627556, 349.228231,
    369.994422, 391.995435, 415.304697, 440.000000, 466.163761, 493.883301,
    // Note C5 - B5
    523.251130, 554.365261, 587.329535, 622.253967, 659.255113, 698.456462,
    739.988845, 783.990871, 830.609395, 880.000000, 932.327523, 987.766602,
    // Note C6 - B6
    1046.502261, 1108.730523, 1174.659071, 1244.507934, 1318.510227, 1396.912925,
    1479.97769, 1567.981743, 1661.21879, 1760, 1864.655046, 1975.533205,
    // Note C7 - B7
    2093.004522, 2217.461047, 2349.318143, 2489.015869, 2637.020455, 2793.825851,
    2959.955381, 3135.963487, 3322.43758, 3520, 3729.310092, 3951.06641,
    // Note C8
    4186.009044
    };
    ```
    
### Step 3: In ViewController.m, - (void)viewDidLoad
#### Add zero padding
    ```
    // Add zero padding if needed
    if (FFTSIZE > AUDIOFRAMELENGTH) {
        for (int i = AUDIOFRAMELENGTH; i < FFTSIZE; i++) {
        audioFrame[i] = 0;
        }
    }
    ```
#### Configure microphone parameters by using a new microphone call function, add a configure function before the end of file
    ```
    self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:[self customAudioStreamBasicDescriptionWithSampleRate:44100.f]];
    
    // insert the following function before the end of implementation
    - (AudioStreamBasicDescription)customAudioStreamBasicDescriptionWithSampleRate:(CGFloat)sampleRate
    {
    AudioStreamBasicDescription asbd;
    UInt32 floatByteSize   = sizeof(float);
    // 每个通道中的位数，1byte = 8bit
    asbd.mBitsPerChannel   = 8 * floatByteSize;
    // 每一帧中的字节数
    asbd.mBytesPerFrame    = floatByteSize;
    // 一个数据包中的字节数
    asbd.mBytesPerPacket   = floatByteSize;
    // 每一帧数据中的通道数，单声道为1，立体声为2
    asbd.mChannelsPerFrame = 1;
    // 每种格式特定的标志，无损编码 ，0表示没有
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
    // 采样数据的类型，PCM,AAC等
    asbd.mFormatID         = kAudioFormatLinearPCM;
    // 一个数据包中的帧数，每个packet的帧数。如果是未压缩的音频数据，值是1。动态帧率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
    asbd.mFramesPerPacket  = 1;
    // 设置采样率：Hz
    // 采样率：Hz
    asbd.mSampleRate       = sampleRate;
    return asbd;
    }
    ```

#### Update fft configuration function
    ```
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:fftSize         sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];
    ```

### Step 4: In ViewController.m, EZMicrophoneDelegate
#### Update audioData array in microphone callback function with each buffer received
    ```
    //
    // Update audioData
    //
    for (int i = 0; i < AUDIODATALENGTH-bufferSize; i++)
    audioData[i] = audioData[i+bufferSize];
    for (int i = 0; i < bufferSize; i++)
    audioData[AUDIODATALENGTH-bufferSize+i] = buffer[0][i];
    ```
    
#### Change FFT function responding to audioFrame Array and FFTSize
    ```
    [self.fft computeFFTWithBuffer:audioFrame withBufferSize:FFTSIZE];
    ```

### Step 5: In ViewController.m, EZAudioFFTDelegate
#### add fft maxFrequencyMagnitude
    ```
    float maxFrequencyMagnitude = [fft maxFrequencyMagnitude];
    ```
    
#### IMPORTANT: Add music recognition algorithm then
