%{
title: "Mobile Development",
description: "Set up the unmaintained Graasp mobile app for local development",
order: 30
}

---

> #### Unmaintained target {: .warning}
>
> The mobile app development has stopped. The native mobile platform is not a currently supported target.
> We recommend the use of the web version which is actively maintained.

This document describes the steps needed to develop on the Graasp mobile app locally.

> #### Info {: .info}
>
> For simplicity we will assume that you are using **macOS** as your operating system and that you have administrator rights.

## Pre-requisite

### XCode (needed to build and run for iOS devices)

You will need to have `XCode` installed if you are planning on running the iOS version of the app.
Download [Xcode in the Mac app Store](https://apps.apple.com/us/app/xcode/id497799835)

Once downloaded:

1. Open XCode
2. Open the Settings `cmd + ,`
3. Go to "Locations" -> "Command Line Tools" and ensure the path is set.

Install `fastlane` and `cocoapods` using brew:

```sh
brew install fastlane cocoapods
```

### Android Studio

> This section might need some more details

If you plan to run the android version you will need `Android Studio`.

Install `openjdk@11` using brew:

```sh
brew install openjdk@11
```

## Configuration files

The project needs configuration files for the google services (firebase).

You should go to [the firebase console](https://console.firebase.google.com) and create a new project.

After that you will need to add iOS and Android sdk to your project (use the little icons on the project page).

The bundle identifier for iOS is `org.graasp.mobile` (defined in `app.config.js`)
The android package name is the same `org.graasp.mobile` (defined in `app.config.js`)

Once you have the `GoogleServices-Info.plist` and the `google-services.json` in your possession you will have to put them somewhere in your computer.

## Building the expo-dev-client locally

In this section we will build an expo-dev-client app that you will be able to install in the iOS or android simulator. This app will then be able to connect to your development sever that will stream the dev bundle. This method supports hot reloading etc.

You should create a `.env.local` file at the root of the project.
You should put the **absolute** path to the Google services config files location.

```sh
GOOGLESERVICE_INFO_PLIST=/Users/basile/<some_more_folders>/GoogleService-Info.plist
GOOGLE_SERVICES_JSON=/Users/basile/<some_more_folders>/google-services.json
```

Also in this file add any environment variables you might need in the app such as hosts for local development.

```sh
EXPO_PUBLIC_API_HOST=http://localhost:3000
EXPO_PUBLIC_AUTH_HOST=http://localhost:3001
```

You should also login once to EAS using `npx eas-cli login`

With this in place you should able to run the command to build the dev-client app:

```sh
npx env-cmd -f .env.local npx eas-cli build -e development-simulator --platform ios --local
```

This command pulls your env variables from the `.env.local` file so they are available to the build process.
Then it runs the build command so to speak.
We are here choosing the `development-simulator` profile which is used to create the simulator app.
We also instruct it to create the build locally.

This command might fail, make sure that you have all the pre-requisites need for it to work.

You can contact basile[at]graasp.org in case of issues.

Once the command finishes, you should see a new file named along the lines of `build-1698223457900.tar.gz` where you executed the build command. you can simply de-compress that file and you will get a `.app` that you can drag-drop inside the open iOS simulator to install it.

## Running the app

Now that you have the dev-client installed in the simulator you can start the dev server using the `yarn start` command.

Then you can press `i` to launch it in the iOS simulator (make sure it is open the first time).

There you go !
