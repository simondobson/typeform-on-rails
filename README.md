# Welcome To Typeform on Rails!

Typeform on Rails is a CLI tool that gives you a quick way to generate some code to live in your Rails project so that your typeform can act as an ActiveRecord model.

## How it works

You run the script with a typeform ID and it uses the [Typeform Create API](https://developer.typeform.com/create/) to get a JSON definition of the typeform, then it goes through each block in the typeform and maps the block type to a Rails type. Next it creates code that will be ready to set up a new ActiveRecord model, then using the IDs of the blocks it can generate code ready to save a submission of the typeform as a new instance of the model. Then all that is needed is to run the generated commands in your Rails project, insert the generated code and set up your Typeform with a [Webhook](https://developer.typeform.com/webhooks/) to the generated URL.

## Use Cases

Provide a personalised, up to date insight of your typeform results on your website. There can be many specific use cases of this, for example:

- Events
    - **Typeform**: Event registration
    - **Rails**: Display who is going, how many spaces are left etc.
- Live poll
    - **Typeform**: Quiz or survey
    - **Rails**: Display the answers as they are received in a nice format

## Limitations & Pre requisites

Limitations:
- Does not work for the following Typeform blocks:
    - Payment
    - Group

Pre requisites:
- Rails 4 or above using ActiveRecord
- Postgres as the Rails DB

## Usage

1. Clone the repository
2. Run `bundle install`
3. Set the environment variable `TYPEFORM_API_TOKEN` to one of your [tokens](https://developer.typeform.com/get-started/personal-access-token/) 
4. Run the script with your typeform's ID as an argument, e.g. `ruby typeform-on-rails.rb r95x3p`
5. Follow the command line instructions

You can run the script in interactive or normal mode, to run it in interactive mode add `-i` to the end of the line executing the script (step 4). This is useful and recommended so that you can define the names of the attributes and the model itself.

## Example

You can look at an example (with example commits) here : https://github.com/simondobson/typeform-on-rails-example

## Contributing

Please feel free to open a pull request!