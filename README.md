# dynamoDMT v0.2b

Filament analysis using Dynamo

aa_setup.m (CPU)
aa_correctFlaDirect.m (CPU) * Important for axoneme not other
aa_imodModel2Filament.m (CPU)
aa_cropAndAverage.m (CPU)
aa_intraAln.m (GPU)
aa_alignIntraAvg.m (CPU)
aa_generateAxonemeAverage.m (CPU) * Optional for axoneme
aa_filamentRepick.m (CPU)
aa_alignRepickAvg.m (CPU)



For doublet MTD, make sense to have a script aa_axonemeIntraAvg.m to generate the average of all dmt from same axoneme to quickly check for polarity.
