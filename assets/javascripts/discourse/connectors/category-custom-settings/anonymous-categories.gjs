import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import withEventValue from "discourse/helpers/with-event-value";
import { i18n } from "discourse-i18n";

export default class AnonymousCategories extends Component {
  static shouldRender(args, context) {
    return !context.siteSettings.enable_simplified_category_creation;
  }

  get forceAnonymousPosting() {
    const value = this.args.category.custom_fields.force_anonymous_posting;
    return value === true || value?.toString() === "true";
  }

  @action
  onChangeSetting(value) {
    this.args.category.set("custom_fields.force_anonymous_posting", value);
  }

  <template>
    <h3>{{i18n "anonymous_categories.title"}}</h3>
    <section class="field">
      <div class="anonymous-categories">
        <label class="checkbox-label">
          <input
            type="checkbox"
            checked={{this.forceAnonymousPosting}}
            {{on "change" (withEventValue this.onChangeSetting "target.checked")}}
          />
          {{i18n "anonymous_categories.force_anonymous_posting"}}
        </label>
      </div>
    </section>
  </template>
}
