Analysis code to produce main figures in manuscript for temporal expectation project. Repo needs a cleanup...

Latest manuscript version [here](https://github.com/moriohamada/temporal_feature_expectation/blob/main/manuscript/manuscript_hamada.pdf).

analysis_pipeline.m is the main runner that calls other runners for different aspects of the analysis: 
- behavioural_analyses:  runs through analysis of behavioural data. Functions in +behaviour.
- neural_responses:      runs through extraction basic neural responses, preferences etc. Relevant functions are in +neural, +single_unit
- expectation_analyses:  runs through expectation-dependent neural effects. Functions in +expectation.
- preparatory_analyses:  frames analysis in terms of motor preparatory dynamics extracted with TDR. 

## License

© 2026 Morio Hamada. All rights reserved.

This repository and its contents are shared for viewing purposes only. 

No permission is granted to copy, modify, distribute, or reproduce any part of this work without explicit written consent from the author.
