import Component from "@glimmer/component";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";

export default class AnonymousCategoriesUpsert extends Component {
  static shouldRender(args, context) {
    return context.siteSettings.enable_simplified_category_creation;
  }

  get forceAnonymousPosting() {
    const value =
      this.args.outletArgs.transientData?.custom_fields
        ?.force_anonymous_posting;

    return value?.toString() === "true";
  }

  @action
  async onToggleForceAnonymousPosting(_, { set, name }) {
    await set(name, this.forceAnonymousPosting ? "false" : "true");
  }

  <template>
    {{#let @outletArgs.form as |form|}}
      <form.Section @title={{i18n "anonymous_categories.title"}}>
        <form.Object @name="custom_fields" as |customFields|>
          <customFields.Field
            @name="force_anonymous_posting"
            @title={{i18n "anonymous_categories.force_anonymous_posting"}}
            @onSet={{this.onToggleForceAnonymousPosting}}
            @type="checkbox"
            as |field|
          >
            <field.Control checked={{this.forceAnonymousPosting}} />
          </customFields.Field>
        </form.Object>
      </form.Section>
    {{/let}}
  </template>
}
