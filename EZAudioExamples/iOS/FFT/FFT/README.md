#  ReadMe
This file explains how to test music recognition algorithm based on short-time Fourier transformc (STFT).
STFT is achieved by frame-wise FFT from EZAudioFFT library.

### Step 1: In ViewController.h
#### (Disabled) replace EZAudioFFTRolling with normal EZAudioFFT in ViewController.h file
    //
    // Used to calculate a normal FFT of the incoming audio data.
    //
    @property (nonatomic, strong) EZAudioFFT *fft;
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:FFTViewControllerFFTWindowSize sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];
#### Continue using EZAudioFFTRolling due to the efficiency of circular buffers
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:fftSize sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];
    
### Step 2: In ViewController.m
#### define a new global array for audio data, named as audioData[AUDIODATALENGTH]
     
    #define AUDIODATALENGTH 4096
    float audioData[AUDIODATALENGTH];
     

#### Add constant array storing fundemantal frequency of 88 piano keys
     
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
    
#### Add strings for all notes

    static const char *notes[] = {
    "A0", "A#0", "B0",
    "C1", "C#1", "D1", "D#1", "E1", "F1", "F#1", "G1", "G#1", "A1", "A#1", "B1",
    "C2", "C#2", "D2", "D#2", "E2", "F2", "F#2", "G2", "G#2", "A2", "A#2", "B2",
    "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3", "G#3", "A3", "A#3", "B3",
    "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4", "A#4", "B4",
    "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5",
    "C6", "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6", "A6", "A#6", "B6",
    "C7", "C#7", "D7", "D#7", "E7", "F7", "F#7", "G7", "G#7", "A7", "A#7", "B7",
    "C8"
    };
    
### Step 3: In ViewController.m, - (void)viewDidLoad
#### Add zero padding
     
    // Add zero padding if needed
    if (FFTSIZE > AUDIOFRAMELENGTH) {
        for (int i = AUDIOFRAMELENGTH; i < FFTSIZE; i++) {
        audioFrame[i] = 0;
        }
    }
     
#### Configure microphone parameters by using a new microphone call function, add a configure function before the end of file
     
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
    
#### Update fft configuration function
     
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:fftSize         sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];
    
### Step 4: In ViewController.m, EZMicrophoneDelegate
#### Update audioData array in microphone callback function with each buffer received
     
    //
    // Update audioData
    //
    for (int i = 0; i < AUDIODATALENGTH-bufferSize; i++)
    audioData[i] = audioData[i+bufferSize];
    for (int i = 0; i < bufferSize; i++)
    audioData[AUDIODATALENGTH-bufferSize+i] = buffer[0][i];
    
#### Change FFT function responding to audioFrame Array and FFTSize
     
    [self.fft computeFFTWithBuffer:audioFrame withBufferSize:FFTSIZE];
    
### Step 5: In ViewController.m, EZAudioFFTDelegate
#### add fft maxFrequencyMagnitude
     
    float maxFrequencyMagnitude = [fft maxFrequencyMagnitude];
    
#### IMPORTANT: Add music recognition algorithm then
#####Algorithm 1:
Key thoughts
  For each frame, 1) apply FFT with length of 8192
                            2) for each F0 candidate
                                2.1) get the vector of  H = 10 harmonics FFT components
                                2.2) if there contains shared harmonics, interpolate the value
                                2.3) determine if the updated vector sum is larger than theshold
                                2.3.1) if so, set thie F0 candidate as matched; substract the vector from fftData; check if all F0's are match; report matching result
                                    2.3.2) if not, break for the next frame
