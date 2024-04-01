# UovoEnergy

_This is version 0.1._

Uovo Energy is an R library that allows you to connect to your Ovo Energy account and download your data.

The library includes a web interface so that you can interact with it through a web browser. This web interface will make the connection and generate the plots for you without you having to write any code.

![Gas plot example](https://github.com/dflores1/UovoEnergy/blob/main/images/gas-example.png?raw=true)

# Disclaimer

*THIS IS NOT AN OFFICIAL OVO ENERGY APPLICATION OR LIBRARY*.

I have no affiliation with the company. I am a private individual providing this code in the hope that it will be useful. I also recommend that you use their official portal to check your energy consumption. Use this code and this application at your own risk.

# Usage

## Docker

If you just want to run the web application and have docker installed on your system, you can just pull the image from the GitHub Container Registry and run it.

```
docker pull ghcr.io/dflores1/uovoenergy:v0.1
docker run -itp 3000:8000 ghcr.io/dflores1/uovoenergy:v0.1 Rscript --vanilla -e 'UovoEnergy::launch()'
```

It should return a link to a webserver running on your computer:

```
Loading required package: shiny

Listening on http://127.0.0.1:5943
```

Simply click on the link, or copy and paste it into your browser, to access the application.

*Important:* This application runs on the computer you run the code on. It doesn't store your connection details anywhere, but I strongly recommend you only use it on a system you trust.

![Webapp screen](https://github.com/dflores1/UovoEnergy/blob/main/images/webapp-example.png?raw=true)

## Install

The easiest way to install this R package from GitHub is with the help of [devtools](https://cran.r-project.org/web/packages/devtools/index.html).

```
library(devtools)
install_github("dflores1/UovoEnergy")
```

## Usage example

Once you have installed the library, you are ready to use it. The following code will connect to your account and download the data in tabular, [tibble](https://tibble.tidyverse.org) form.

```
library(UovoEnergy)

cookie <- connect("your@email.com", "yourpwd")
data.tbl <- getData(cookie)
disconnect(cookie)
```

This will return a tibble table with your account information. You can inspect it and work with it:

```
> data.tbl |> anonymise()
# A tibble: 1,515 × 10
   Consumption Date        Cost RateAnytime RateStanding Utility AccountId Year
         <dbl> <date>     <dbl>       <dbl>        <dbl> <fct>   <fct>     <fct>
 1        3.74 2021-12-08 1.359       0.607        0.163 Electr… romantic… 2021
 2        3.75 2021-12-09 1.362       0.607        0.163 Electr… romantic… 2021
 3        3.74 2021-12-10 1.360       0.607        0.163 Electr… romantic… 2021
 4        3.74 2021-12-11 1.340       0.597        0.160 Electr… romantic… 2021
 5        3.81 2021-12-12 1.362       0.597        0.271 Electr… romantic… 2021
 6        3.9  2021-12-13 1.369       0.597        0.271 Electr… romantic… 2021
 7        3.73 2021-12-14 1.340       0.597        0.271 Electr… romantic… 2021
 8        3.71 2021-12-15 1.342       0.597        0.271 Electr… romantic… 2021
 9        3.71 2021-12-16 1.338       0.597        0.271 Electr… romantic… 2021
10        3.71 2021-12-17 1.338       0.597        0.271 Electr… romantic… 2021
# ℹ 1,333 more rows
# ℹ 2 more variables: JDay <dbl>, Consumptiom <dbl>
# ℹ Use `print(n = ...)` to see more rows
```

Of course, there is no need to make your data anonymous to your own eyes.

### Making a plot

Once you have loaded your data into a tibble data frame, you can use the helper functions to create plots. The following example creates a plot of electricity consumption.

```
electricity.tbl <- filterByUtility(data.tbl, "Electricity")
electricity.tbl <- filterByYears(electricity.tbl, c(2022, 2023))
electricity.tbl <- anonymise(electricity.tbl)
electricity.tbl <- rollingwindow(electricity.tbl, "Consumption", 12)
plotConsumption(electricity.tbl)
```

![Electricity plot example](https://github.com/dflores1/UovoEnergy/blob/main/images/electricity-example.png?raw=true)

#### Alternative coding styles

The previous example was is just the old-fashioned imperative way. Alternatively, you can use the R [pipe operators](https://www.r-bloggers.com/2021/05/the-new-r-pipe/) to link the different steps.


```
data.tbl |>
	filterByUtility("Electricity") |>
	filterByYears(c(2022, 2023)) |>
	anonymise() |>
	rollingMean("Consumption", 12) |>
	plotConsumption()
```

Here I am using the R native operators (which have been introduced in R since version 4.1.0.), but you can also use the [magrittr operators](https://magrittr.tidyverse.org) to get the same results.


Finally, here is another way to get the same plot:

```
makeConsumptionPlot(data.tbl, "Electricity", c(2022, 2023), FALSE, 12, FALSE, FALSE)
```

### Running the web app

This package includes a [shiny](https://shiny.posit.co) web application, which is what we run with the docker image. To run it from your R interpreter, all you need to do is 'launch' it.

```
launch()
```

```
Loading required package: shiny

Listening on http://127.0.0.1:6358
```

The listening port is randomly assigned between 3000 and 8000.

# NIX

This package has been developed alongside with a flake.nix derivation for the [Nix](https://github.com/NixOS/nix) package manager and/or the [Nixos](https://nixos.org) operating system. This system allows for reproducible builds and has some beneficts.

## Run the shinny web app

If you have [flakes](https://nixos.wiki/wiki/Flakes) support enabled in Nix, you can simply run the server as follows.

```
nix run github:dflores1/UovoEnergy
```

## Developing

For those who want to write their own code:

```
nix develop github:dflores1/UovoEnergy

$ R
```

## Install the R package

```
nix profile install github:dflores1/UovoEnergy
```

# License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [<http://www.gnu.org/licenses/>](http://www.gnu.org/licenses/).
