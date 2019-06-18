# Open Science Identifier

This repository contains reference implementations for the Open Science Identifier, developed at the [McGill Centre for Integrative Neuroscience](mcin.ca).

## What is it?
The Open Science Identifier is a free and open-source mechanism that allows for linking of de-identified data collected on a subject across studies.

## Why would I need it?
It is common that a subject participates in multiple neurological studies. While data is being collected, each study will represent a single subjct using different identifiers in order to preserve anonymity and fulfill ethical obligations to the privacy of subjects.

This effectively "splits" the identity of a single subject into multiple identities in different projects.

If these studies are later published in an Open Data context, it is of great value to be able to reconstitute the split identities into a single subject. 

The Open Science Identifier makes this possible -- _without_ storing personal information on a subject.

## How does it work?
The Identifier is the result of a one-way hashing algorithm. It can be stored privately within a study to identify a subject within a database.

When it comes time to publish data in an open context, they can be linked used the identifier.

The hash is generated using personally-identifying information as input. This allows each ID to be unique to a subject and eliminates the need to store personally-identifying information.

Ihe particular inputs are:
* first, middle, and last names
* date of birth
* city of birth

These inputs were chosen based on [existing research](https://doi.org/10.1136/jamia.2009.002063) demonstrating that they are the most reliably collected (in contrast to other PII options, e.g. mother’s maiden name).


## How to Help
* Please join the discussion on the Issues tab!
* Expand our test dataset! Create fake subject information and help us verify that every implementation gives the same result.

### Milestones
(June 2019)
**Complete** implementations:
* Ruby
* PHP
* JavaScript

**Parital** implementations
* Perl

Future implementations:
Python
