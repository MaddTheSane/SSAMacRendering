# SSAMacRendering

SSAMacRendering is an SSA/ASS parser and render that uses Apple's frameworks. Taken from [Perian](https://perian.org).

# Deprecation Warnings
* This framework was originally programmed to use  Apple Type Services (ATS), which has been deprecated since 10.8 and was removed in 14.0. CoreText is very much being worked on.
* The included Ragel parser is version 5.25. This is due to the fact that the Ragel file does not parse in version 6.

# TODO:
* There are some parts of the SSA standard that we are not implemented in the SubATSUIRenderer. For instance, shapes don't match the reference render of libassimp.
