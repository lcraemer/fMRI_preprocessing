# Gabor-Bandit fMRI Preprocessing

This repository contains the code to preprocess Gabor-Bandit fMRI data.

## Getting Started

The code requires [BIDS](http://bids.neuroimaging.io) formatted data. Preprocessing stepts include realignment, normalization and smoothing. We have two main files:

* gb_preprocessing: This script preprocesses the Gabor-Bandit fMRI data
* gb_prepobj: Gabor-bandit preprocessing class definition file

Add the gb_preprocessing folder to the Matlab path. In the gb_preprocessing script, add the SPM path and indicate where the BIDS data directory is located. 

## Built With

* [Matlab](https://de.mathworks.com/products/matlab.html)
* [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

## Acknowledgements

* The code is based on preprocessing code from [Dirk Ostwald's lab at FU Berlin](https://www.ewi-psy.fu-berlin.de/einrichtungen/arbeitsbereiche/computational_cogni_neurosc/research/index.html)
* [bioRxiv preprint](https://www.biorxiv.org/content/10.1101/253047v1)
* [OSF project](https://osf.io/hkevu/)

## Authors

* **Rasmus Bruckner** - [GitHub](https://github.com/rasmusbruckner) - [IMPRS LIFE](https://www.imprs-life.mpg.de/de/people/rasmus-bruckner)
* **Felix Molter** - [IMPRS LIFE](https://www.imprs-life.mpg.de/de/people/felix-molter)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
