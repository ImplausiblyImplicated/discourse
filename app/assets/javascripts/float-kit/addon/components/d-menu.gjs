import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { getOwner } from "@ember/application";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import { inject as service } from "@ember/service";
import { modifier } from "ember-modifier";
import { and } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import concatClass from "discourse/helpers/concat-class";
import { isTesting } from "discourse-common/config/environment";
import DFloatBody from "float-kit/components/d-float-body";
import { MENU } from "float-kit/lib/constants";
import DMenuInstance from "float-kit/lib/d-menu-instance";

export default class DMenu extends Component {
  @service menu;
  @service site;

  registerTrigger = modifier((element) => {
    if (!this.menuInstance.trigger) {
      next(() => {
        this.menuInstance.trigger = element;
        this.options.onRegisterApi?.(this.menuInstance);
      });
    }
  });

  @cached
  get menuInstance() {
    return new DMenuInstance(getOwner(this), {
      ...this.allowedProperties(),
      ...{
        autoUpdate: true,
        listeners: true,
      },
    });
  }

  get menuId() {
    return `d-menu-${this.menuInstance.id}`;
  }

  get options() {
    return this.menuInstance?.options ?? {};
  }

  get componentArgs() {
    return {
      close: this.menuInstance.close,
      data: this.options.data,
    };
  }

  @action
  allowedProperties() {
    const properties = {};
    Object.keys(MENU.options).forEach((key) => {
      const value = MENU.options[key];
      properties[key] = this.args[key] ?? value;
    });
    return properties;
  }

  <template>
    <DButton
      class={{concatClass
        "fk-d-menu__trigger"
        (if this.menuInstance.expanded "-expanded")
        (concat this.options.identifier "-trigger")
        @triggerClass
      }}
      id={{this.menuInstance.id}}
      data-identifier={{this.options.identifier}}
      data-trigger
      @icon={{@icon}}
      @translatedAriaLabel={{@ariaLabel}}
      @translatedLabel={{@label}}
      @translatedTitle={{@title}}
      @disabled={{@disabled}}
      aria-expanded={{if this.menuInstance.expanded "true" "false"}}
      {{this.registerTrigger}}
      ...attributes
    >
      {{#if (has-block "trigger")}}
        {{yield this.componentArgs to="trigger"}}
      {{/if}}
    </DButton>

    {{#if this.menuInstance.expanded}}
      {{#if (and this.site.mobileView this.options.modalForMobile)}}
        <DModal
          @closeModal={{this.menuInstance.close}}
          @hideHeader={{true}}
          class={{concatClass
            "fk-d-menu-modal"
            (concat this.options.identifier "-content")
          }}
          @inline={{(isTesting)}}
          data-identifier={{@instance.options.identifier}}
          data-content
        >
          {{#if (has-block)}}
            {{yield this.componentArgs}}
          {{else if (has-block "content")}}
            {{yield this.componentArgs to="content"}}
          {{else if this.options.component}}
            <this.options.component
              @data={{this.options.data}}
              @close={{this.menuInstance.close}}
            />
          {{else if this.options.content}}
            {{this.options.content}}
          {{/if}}
        </DModal>
      {{else}}
        <DFloatBody
          @instance={{this.menuInstance}}
          @trapTab={{this.options.trapTab}}
          @mainClass={{concatClass
            "fk-d-menu"
            "fk-d-menu__content"
            (concat this.options.identifier "-content")
          }}
          @innerClass="fk-d-menu__inner-content"
          @role="dialog"
          @inline={{this.options.inline}}
        >
          {{#if (has-block)}}
            {{yield this.componentArgs}}
          {{else if (has-block "content")}}
            {{yield this.componentArgs to="content"}}
          {{else if this.options.component}}
            <this.options.component
              @data={{this.options.data}}
              @close={{this.menuInstance.close}}
            />
          {{else if this.options.content}}
            {{this.options.content}}
          {{/if}}
        </DFloatBody>
      {{/if}}
    {{/if}}
  </template>
}
