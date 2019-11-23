#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

# Assume that the proper MonetDB version is already installed.
today=$(date +%Y-%m-%dT%H:%M:%S)

# Install the latest version of MonetDB

# Collect the simple stuff first
vertical_run.sh -d SF-1 -m plan -t ${today}
vertical_run.sh -d SF-10 -m plan -t ${today}
vertical_run.sh -d SF-100 -m plan -t ${today}

vertical_run.sh -d SF-1 -m explain -t ${today}
vertical_run.sh -d SF-10 -m explain -t ${today}
vertical_run.sh -d SF-100 -m explain -t ${today}

# Run the benchmark a number of times, should fit within the day
# Run a hot trace to get an impression of the cost distribution on MAL level
vertical_run.sh -d SF-1 -n 3 -t ${today}
vertical_run.sh -d SF-1 -m trace -t ${today}

vertical_run.sh -d SF-10 -n 3 -t ${today}
vertical_run.sh -d SF-10 -m trace -t ${today}

vertical_run.sh -d SF-100 -n 3 -t ${today}
vertical_run.sh -d SF-100 -m trace -t ${today}

