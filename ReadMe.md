# SSAMacRendering

SSAMacRendering is an SSA/ASS parser and render that uses Apple's frameworks. Taken from [Perian](https://perian.org).

# Deprecation Warnings
* As it stands, this framework uses Apple Type Services \(ATS\), which has been deprecated since 10.8 and was removed in 14.0. Work is being done to update it to use CoreText instead.
* The included Ragel parser is version 5.25. This is due to the fact that the Ragel file does not parse in version 6.
