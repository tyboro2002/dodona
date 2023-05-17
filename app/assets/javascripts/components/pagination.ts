import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { search } from "search";
import { searchQueryState } from "state/SearchQuery";

/**
 * This component represents a pagination component as commonly found at the bottom of a paginated list page
 * The behaviour should be very similar to the rails native pagination generated by will_paginate
 *
 * @element d-pagination
 *
 * @prop {Number} current - current page
 * @prop {Number} total - total number of pages
 * @prop {Boolean} small - render less pages to minimize width
 */
@customElement("d-pagination")
export class Pagination extends ShadowlessLitElement {
    @property({ type: Number })
    total: number;
    @property({ type: Number })
    current: number;
    @property({ type: Boolean })
    small = false;

    get width(): number {
        return this.small ? 1 : 2;
    }

    get range(): number[] {
        const rangeStart = Math.max(2, Math.min(this.current - this.width, this.total - 2 * this.width));
        const rangeEnd = Math.min(this.total-1, Math.max( this.current + this.width, 1 + 2 * this.width));
        if (rangeEnd < rangeStart) {
            return [];
        }

        const len = rangeEnd - rangeStart + 1;
        return Array.from({ length: len }, (x, i) => i + rangeStart);
    }

    gotToPage(page: number): void {
        searchQueryState.queryParams.set("page", page.toString());
    }

    pageButton(page?: number, text?: string): TemplateResult {
        return html`
            <li class="page-item ${page === undefined || page < 1 || page > this.total ? "disabled" : ""} ${page === this.current ? "active" : ""}">
                <a class="page-link" @click=${() => this.gotToPage(page)} @mousedown=${e => e.preventDefault()} href="#">
                    ${text !== undefined ? text : page.toString()}
                </a>
            </li>
        `;
    }


    render(): TemplateResult {
        return this.total > 1 ? html`
            <center>
                <ul role="navigation" class="pagination">
                    ${!this.small ? this.pageButton(this.current - 1, "←") : ""}
                    ${this.pageButton(1)}
                    ${this.total > 3 + 2 * this.width && this.current == 3 + this.width ? this.pageButton(2) : ""}
                    ${this.total > 3 + 2 * this.width && this.current > 3 + this.width ? this.pageButton(undefined, "…") : ""}
                    ${this.range.map(i => this.pageButton(i))}
                    ${this.total > 3 + 2 * this.width && this.total - this.current > 2 + this.width ? this.pageButton(undefined, "…") : ""}
                    ${this.total > 3 + 2 * this.width && this.total - this.current == 2 + this.width ? this.pageButton(this.total - 1) : ""}
                    ${this.pageButton(this.total)}
                    ${!this.small ? this.pageButton(this.current + 1, "→"): ""}
                </ul>
            </center>
        `: html``;
    }
}
